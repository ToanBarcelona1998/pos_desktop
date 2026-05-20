# Flow in hoá đơn qua máy in nhiệt USB (Android POS)

Doc này là single source of truth cho luồng in. Tổng hợp cả thiết kế gốc,
implementation hiện tại trong repo, các bug đã gặp + fix, debug mode, và
contract giữa app Flutter ↔ webview JS.

Ngữ cảnh: app Flutter chạy trên Android POS (đã test với Gprinter iTP9
80mm). Máy in cắm USB qua OTG. Webview (`flutter_inappwebview`) chạy site
POS; JS bên trong tự sinh PDF → gửi base64 sang Dart qua JavaScript
handler `execute_print` → Dart render PDF → ESC/POS → USB.

---

## Stack thực tế

- `flutter_pos_printer_platform_image_3_sdt`: backend native USB
  (MethodChannel → `UsbManager.deviceList` + `UsbDeviceConnection`).
  Dùng trực tiếp cho cả discovery lẫn connect/send.
- `esc_pos_utils_plus`: sinh lệnh ESC/POS (`Generator.image / feed / cut`).
- `pdfx`: render PDF → bitmap (PNG) trong RAM, **bounded width**.
- `image`: decode PNG → `img.Image` để feed vào `Generator.image`.
- `path_provider`: lấy temp/cache dir cho cleanup PDF tồn đọng.

Tham chiếu code:

- `lib/src/core/services/thermal_print_service.dart`: pipeline & cache.
- `lib/src/presentation/pages/pos_online/pos_online_page.dart`: JS handler
  `execute_print` + debug dialog (debug build only).

---

## Permission Android

`android/app/src/main/AndroidManifest.xml`:

```xml
<uses-feature android:name="android.hardware.usb.host"/>
```

Lần đầu cắm máy in, Android sẽ pop dialog xin quyền USB cho app — bấm
Allow. Nếu app khác (Fabi, …) đang giữ thiết bị, force stop app đó trước
rồi rút–cắm lại cáp.

---

## Pipeline

```
JS (webview)
  └─ window.handleAppRequest('execute_print', base64Pdf)
       └─ Dart handler `execute_print` trong PosOnlinePage
            ├─ decodePdfBase64(raw)                       (data URL prefix optional)
            └─ ThermalPrintService.printPdfBytes(bytes)
                 ├─ resolve target USB printer
                 │     1. param printer
                 │     2. _cachedPrinter
                 │     3. discoverPrinters() rồi pick first
                 ├─ renderPdfToPngPages(bytes, 576dot)    (pdfx, memory-bounded)
                 ├─ esc.Generator(mm80).image(...)        (mỗi page)
                 ├─ connect(usb, model)
                 ├─ send(escBytes)
                 └─ finally: _cleanupTempPdfs()
```

### Discovery (lấy danh sách máy in USB)

```dart
final stream = pos.PrinterManager.instance.discovery(type: pos.PrinterType.usb);

final found = <UsbPrinter>[];
final seen = <String>{};
await for (final device in stream.timeout(
  const Duration(seconds: 5),
  onTimeout: (sink) => sink.close(),
)) {
  final vid = device.vendorId ?? '';
  final pid = device.productId ?? '';
  if (vid.isEmpty || pid.isEmpty) continue;
  if (!seen.add('$vid:$pid')) continue;
  found.add(UsbPrinter(name: device.name, vendorId: vid, productId: pid));
}
```

Notes:

- Native `getList` là 1 MethodChannel call duy nhất, trả tức thì → 5s là dư.
- `device.vendorId` / `device.productId` là **chuỗi thập phân** (vd `"1155"`,
  `"22336"`), KHÔNG phải hex.
- Phải dedup tay theo `vid:pid` vì model gốc không override `==`.

### Render PDF → PNG → ESC/POS

```dart
const targetWidth = 576; // 80mm @ 203 DPI; 58mm dùng 384.

final document = await PdfDocument.openData(pdfBytes);
try {
  for (int i = 1; i <= document.pagesCount; i++) {
    final page = await document.getPage(i);
    try {
      final pageImage = await page.render(
        width: targetWidth.toDouble(),
        height: page.height * (targetWidth / page.width),
        format: PdfPageImageFormat.png,
      );
      final decoded = img.decodePng(pageImage!.bytes);
      escBytes.addAll(generator.image(decoded!));
    } finally {
      await page.close();
    }
  }
} finally {
  await document.close();
}
escBytes.addAll(generator.feed(2));
escBytes.addAll(generator.cut());                       // chỉ gọi 1 lần ở cuối
```

### Connect + send

```dart
final connected = await pos.PrinterManager.instance.connect(
  type: pos.PrinterType.usb,
  model: pos.UsbPrinterInput(
    name: printer.name, vendorId: printer.vendorId, productId: printer.productId,
  ),
);
if (!connected) throw Exception('Không thể kết nối máy in USB');

await pos.PrinterManager.instance.send(
  type: pos.PrinterType.usb,
  bytes: escBytes,
);
```

---

## Caching & performance

- `UsbPrinter` được cache trong `_cachedPrinter` sau lần connect thành công.
  Lần in tiếp theo bỏ qua 5s discovery. Connect fail → invalidate cache
  → rediscover. Reset thủ công bằng `ThermalPrintService.clearCachedPrinter()`
  nếu user rút–cắm sang máy khác.
- `esc.CapabilityProfile` được cache trong `_cachedProfile` (lần đầu load
  chậm vài trăm ms, lần sau O(1)).
- Render bitmap 576dot có thể chậm vài trăm ms; chưa wrap `compute()`/isolate
  vì hiện tại không cần. Khi cần (bill rất nhiều trang), wrap
  `_renderPdfToEscPos` trong isolate.

---

## Contract JS ↔ Dart

JS bên webview gọi handler:

```js
window.handleAppRequest('execute_print', base64Pdf);
// hoặc base64Pdf = "data:application/pdf;base64,JVBERi0..."
// hoặc array [base64Pdf], hoặc { pdf: base64Pdf } | { data, base64, content }
```

Handler `execute_print` (file `pos_online_page.dart`) extract base64 từ
arg theo các shape: `String` / `List<String>` / `Map<String, dynamic>`
với key `pdf|data|base64|content`. Trả về:

- `'success'` — in xong.
- `'error: empty_payload'` — không decode được arg.
- `'error: <message>'` — lỗi runtime (USB không có, connect fail, …).

### Page format expectation

**JS PHẢI generate PDF ở khổ 80mm** (page width ≈ 227pt) hoặc 72mm
(≈204pt). KHÔNG dùng A4 (595×841pt = 210×297mm).

**Lý do**: pipeline render scale theo `page.width` xuống 576dot. Nếu PDF
gốc là A4 (210mm), khi nén xuống 80mm thì text chỉ còn ~38% kích thước
gốc → bill in ra rất nhỏ. Lỗi này đã từng gặp; debug dialog (dưới) sẽ
hiển thị page size để verify.

---

## Debug dialog (debug build only)

Trong `pos_online_page.dart`, handler `execute_print` gọi
`_maybeShowPdfDebugDialog` trước khi in, bọc trong `if (kDebugMode)`.
`kDebugMode` là `const false` ở release → AOT compiler tree-shake toàn
bộ block + method + widget `_DebugPdfColumn` → không tốn binary size.

Dialog show 2 cột Image.memory:

- **Preview** (1080dot): render giả lập chất lượng cao để đọc text.
- **Thermal** (576dot): **đúng những gì máy in nhận**.

Header dialog hiển thị page dimensions: `Page: X × Y mm (W × H pt) | pages=N`.
Nếu thấy `210 × 297 mm` → JS đang sinh A4, phải sửa bên JS.

### Tại sao KHÔNG dùng `PdfPreview` từ package `printing`

Lần đầu thử dùng `PdfPreview` (printing package) bị OOM:

```
java.lang.OutOfMemoryError: Failed to allocate a 174159048 byte allocation
  at io.flutter.plugin.common.StandardMessageCodec.writeBytes(...)
  at net.nfet.flutter.printing.PrintingHandler.onPageRasterized(...)
```

Root cause: `printing.raster()` rasterize qua native `PdfRenderer` ở
`72 × devicePixelRatio` DPI (~216 trên màn 3x). Với PDF page lớn (A4
hoặc custom oversized), 1 trang ra > 170MB bitmap. MethodChannel cố
serialize cả bytes về Dart → OOM.

**Fix**: bỏ hẳn `PdfPreview`. Render bằng `pdfx` ở **bounded width**
(`width × height × 4` mình control). Display dưới dạng `Image.memory`
trong `ListView`. Worst-case A4 ở 1080dot ≈ 6.6MB/page — an toàn.

---

## Temp file cleanup

`pdfx.PdfDocument.openData()` trên Android nội bộ ghi PDF ra một file
trong cache dir để feed cho `PdfRenderer` của platform. `document.close()`
thường tự xoá. Để defensive:

```dart
finally {
  await _cleanupTempPdfs();         // scan temp + cache, xoá *.pdf còn lại
}
```

`_cleanupTempPdfs` chạy sau **mỗi** lần `printPdfBytes`. Bọc try/catch
nên không ảnh hưởng flow in.

App của ta **không** chủ động ghi PDF ra disk — toàn bộ pipeline là
`Uint8List` trong RAM. Cleanup này thuần defensive.

---

## Gotcha đã gặp (giữ làm reference)

1. **`quick_print.PrinterDiscoveryService.initialize()/dispose()/discoverDevices()`**
   gọi `WinBle.initialize / startScanning / stopScanning / dispose` không
   điều kiện → trên Android/iOS/macOS spawn `WinBleServer.exe` → ném
   `ProcessException: Permission denied`. ⇒ **Không dùng**
   `PrinterDiscoveryService`; gọi thẳng `pos.PrinterManager.instance.discovery`.
2. **`PrinterDiscoveryService.discoverDevices(timeout)`** default chờ 5s
   mới gọi USB scan → caller wait 3s sẽ đọc list khi USB chưa quét xong.
3. **`quick_print.instance.printPdf(...)` ném `InvalidFileException`** vì
   `IPrinterMixin.convertPdfToImage()` render PNG nhưng
   `img.decodeJpg(image.bytes)` → `null` → throw. ⇒ Tự pipeline render
   PNG + decode đúng định dạng.
4. **Conflict tên `PdfDocument`** giữa `package:pdf/pdf.dart` và
   `package:pdfx/pdfx.dart`. ⇒ `import 'package:pdf/pdf.dart' show PdfPageFormat;`.
5. **`dart:typed_list`** không tồn tại. Đúng là `dart:typed_data`.
6. **`PdfPreview` (printing package) OOM** — đã giải thích ở mục debug.
7. **JS sinh PDF A4 thay vì 80mm** → bill in ra siêu nhỏ. Verify bằng
   debug dialog header (page dimensions).

---

## Files được sửa khi implement

- `pubspec.yaml`: thêm `flutter_pos_printer_platform_image_3_sdt`,
  `esc_pos_utils_plus`, `pdfx`, `image`.
- `android/app/src/main/AndroidManifest.xml`: thêm `uses-feature usb.host`.
- `lib/src/core/services/thermal_print_service.dart`: pipeline + cache +
  cleanup.
- `lib/src/presentation/pages/pos_online/pos_online_page.dart`: JS handler
  `execute_print` + debug dialog gated bởi `kDebugMode`.

---

## TL;DR cho người mới

1. JS gửi base64 PDF qua handler `execute_print`. PDF **phải** là khổ
   80mm (không phải A4).
2. Dart decode → `pdfx` render PNG 576dot/page → `esc_pos_utils_plus`
   sinh ESC/POS → gửi qua `flutter_pos_printer_platform_image_3_sdt`.
3. Cache USB printer + capability profile để in lần 2 nhanh.
4. Debug build có dialog so sánh preview vs thermal — không tốn binary
   ở release vì gated bằng `kDebugMode`.
5. Sau mỗi lần in, dọn `.pdf` tồn đọng trong temp/cache dir.
