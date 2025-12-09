import 'dart:async';

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:printing/printing.dart';
/// Print service for printing invoices
/// Handles invoice generation and printing
class PrintService {
  /// Print invoice for a sell
  ///
  /// [sellId] - The ID of the sell to print
  /// [taxId] - Optional tax ID
  /// [context] - BuildContext for localization
  /// [invoiceHtml] - Optional pre-generated invoice HTML (from API)
  static Future<void> printInvoice({
    required int sellId,
    int? taxId,
    required BuildContext context,
    required String invoiceHtml,
    required String name,
  }) async {
    try {
      final Completer<Uint8List?> completer = Completer();

      Uint8List ? pdfBytes;
      if (Platform.isWindows || Platform.isMacOS) { // [TODO] should be have a webview on page and hidden it.
        // final InAppWebView webView = InAppWebView(
        //   initialUrlRequest: URLRequest(
        //     url: WebUri.uri(
        //       Uri.dataFromString(
        //         invoiceHtml,
        //         mimeType: 'text/html',
        //         encoding: Utf8Codec(),
        //       ),
        //     ),
        //   ),
        //   onWebViewCreated: (controller) async{
        //     pdfBytes = await controller.createPdf();
        //     completer.complete(pdfBytes);
        //   },
        // );
      } else {
        pdfBytes = await Printing.convertHtml(html: invoiceHtml);

        completer.complete(pdfBytes);
      }

      final bytes = await completer.future;

      if(bytes != null){
        // Print the invoice
        await Printing.layoutPdf(
          onLayout: (format) {
            return bytes;
          },
          name: name,
        );
      }
    } catch (e) {
      throw Exception('Failed to print invoice: $e');
    }
  }
}
