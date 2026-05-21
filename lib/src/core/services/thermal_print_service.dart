import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart' as esc;
import 'package:flutter_pos_printer_platform_image_3_sdt/flutter_pos_printer_platform_image_3_sdt.dart'
    as pos;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:pos_final/src/core/utils/dart_core_extension.dart';

/// Pipeline in hoá đơn qua máy in nhiệt USB (Android POS).
///
/// Tham chiếu: docs/PRINTING_FLOW.md.
class ThermalPrintService {
  ThermalPrintService._();

  /// Chuẩn 80mm @ 203 DPI = 576 dot. Dùng 384 nếu chuyển sang 58mm.
  static const int thermalDotWidth = 576;

  /// Chiều rộng PNG dùng cho preview gốc — đủ cao để text rõ, đủ thấp để
  /// không OOM trên Android (576dot ≈ 80mm thì preview hơi mờ).
  static const int previewDotWidth = 1080;

  static esc.CapabilityProfile? _cachedProfile;

  /// Máy in được dùng gần nhất — skip discovery lần sau.
  /// Reset bằng [clearCachedPrinter] nếu user rút–cắm máy in khác.
  static UsbPrinter? _cachedPrinter;

  static UsbPrinter? get cachedPrinter => _cachedPrinter;

  static void clearCachedPrinter() => _cachedPrinter = null;

  /// Discovery USB. Trả về list dedup theo `vid:pid` (xem PRINTING_FLOW.md).
  static Future<List<UsbPrinter>> discoverPrinters({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final stream =
        pos.PrinterManager.instance.discovery(type: pos.PrinterType.usb);

    final found = <UsbPrinter>[];
    final seen = <String>{};

    await for (final device in stream.timeout(
      timeout,
      onTimeout: (sink) => sink.close(),
    )) {
      final vid = device.vendorId ?? '';
      final pid = device.productId ?? '';
      if (vid.isEmpty || pid.isEmpty) continue;
      if (!seen.add('$vid:$pid')) continue;
      found.add(UsbPrinter(
        name: device.name,
        vendorId: vid,
        productId: pid,
      ));
    }

    return found;
  }

  /// In bytes PDF qua USB. Thứ tự pick target:
  /// 1. [printer] truyền vào — 2. [_cachedPrinter] — 3. discovery rồi pick first.
  /// Nếu connect fail → invalidate cache để lần sau rediscover.
  ///
  /// Mọi temp `.pdf` còn sót trong cache/temp dir (pdfx có thể tạo khi
  /// `openData` trên Android) sẽ được dọn sạch trong `finally`.
  static Future<void> printPdfBytes(
    Uint8List pdfBytes, {
    UsbPrinter? printer,
  }) async {
    try {
      UsbPrinter? target = printer ?? _cachedPrinter;
      if (target == null) {
        final discovered =
            await discoverPrinters(timeout: const Duration(seconds: 5));
        
        target = discovered.firstWhereOrNull((e) => e.name.toLowerCase().contains('itp9'));
      }
      if (target == null) {
        throw Exception('Không tìm thấy máy in USB');
      }

      final escBytes = await _renderPdfToEscPos(pdfBytes);

      final connected = await pos.PrinterManager.instance.connect(
        type: pos.PrinterType.usb,
        model: pos.UsbPrinterInput(
          name: target.name,
          vendorId: target.vendorId,
          productId: target.productId,
        ),
      );
      if (!connected) {
        _cachedPrinter = null;
        throw Exception('Không thể kết nối máy in USB ${target.name}');
      }
      _cachedPrinter = target;

      await pos.PrinterManager.instance.send(
        type: pos.PrinterType.usb,
        bytes: escBytes,
      );
    } finally {
      await _cleanupTempPdfs();
    }
  }

  /// Dọn `.pdf` còn sót trong temp + cache dir. pdfx khi `PdfDocument.openData`
  /// trên Android có thể ghi PDF ra file để feed cho `PdfRenderer` của
  /// platform; `document.close()` thường tự xoá, nhưng nếu flow bị crash giữa
  /// chừng file sẽ tồn đọng. Method này chạy sau mỗi lần in để đảm bảo sạch.
  /// Bọc try/catch để failure không làm fail flow in.
  static Future<void> _cleanupTempPdfs() async {
    Future<void> sweep(Directory dir) async {
      try {
        if (!await dir.exists()) return;
        await for (final entry in dir.list(followLinks: false)) {
          if (entry is File &&
              entry.path.toLowerCase().endsWith('.pdf')) {
            try {
              await entry.delete();
            } catch (_) {}
          }
        }
      } catch (_) {}
    }

    try {
      final temp = await getTemporaryDirectory();
      await sweep(temp);
    } catch (_) {}
    try {
      final cache = await getApplicationCacheDirectory();
      await sweep(cache);
    } catch (_) {}
  }

  /// Giải mã base64 PDF nhận từ webview. Hỗ trợ cả data URL prefix.
  static Uint8List decodePdfBase64(String raw) {
    String trimmed = raw.trim();
    if (trimmed.startsWith('data:')) {
      final commaIdx = trimmed.indexOf(',');
      if (commaIdx != -1) {
        trimmed = trimmed.substring(commaIdx + 1);
      }
    }
    return base64Decode(trimmed);
  }

  /// Render PDF → PNG có metadata page size (pt). Width PNG bị bound bởi
  /// [targetWidth] → memory-safe bất kể source PDF to cỡ nào.
  static Future<List<PdfPagePreview>> renderPdfToPngPages(
    Uint8List pdfBytes, {
    int targetWidth = thermalDotWidth,
  }) async {
    final document = await PdfDocument.openData(pdfBytes);
    final pages = <PdfPagePreview>[];
    try {
      for (int i = 1; i <= document.pagesCount; i++) {
        final page = await document.getPage(i);
        try {
          final pageImage = await page.render(
            width: targetWidth.toDouble(),
            height: page.height * (targetWidth / page.width),
            format: PdfPageImageFormat.png,
          );
          if (pageImage == null) {
            throw Exception('PDF render page $i fail');
          }
          pages.add(PdfPagePreview(
            png: pageImage.bytes,
            widthPt: page.width,
            heightPt: page.height,
          ));
        } finally {
          await page.close();
        }
      }
    } finally {
      await document.close();
    }
    return pages;
  }

  static Future<List<int>> _renderPdfToEscPos(Uint8List pdfBytes) async {
    final pngPages =
        await renderPdfToPngPages(pdfBytes, targetWidth: thermalDotWidth);

    final profile = _cachedProfile ??= await esc.CapabilityProfile.load();
    final generator = esc.Generator(esc.PaperSize.mm80, profile);

    final escBytes = <int>[...generator.reset()];
    for (final p in pngPages) {
      final decoded = img.decodePng(p.png);
      if (decoded == null) {
        throw Exception('Decode PNG fail');
      }
      escBytes.addAll(generator.image(decoded));
    }
    escBytes
      ..addAll(generator.feed(2))
      ..addAll(generator.cut());

    return escBytes;
  }
}

class PdfPagePreview {
  final Uint8List png;
  final double widthPt;
  final double heightPt;

  const PdfPagePreview({
    required this.png,
    required this.widthPt,
    required this.heightPt,
  });

  /// 1 pt = 1/72 inch; 1 inch = 25.4 mm → mm = pt / 2.83465.
  double get widthMm => widthPt / 2.83465;
  double get heightMm => heightPt / 2.83465;
}

class UsbPrinter {
  final String name;
  final String vendorId;
  final String productId;

  const UsbPrinter({
    required this.name,
    required this.vendorId,
    required this.productId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UsbPrinter &&
          vendorId == other.vendorId &&
          productId == other.productId;

  @override
  int get hashCode => Object.hash(vendorId, productId);

  @override
  String toString() => 'UsbPrinter($name, $vendorId:$productId)';
}
