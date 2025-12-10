import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
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
      Uint8List pdfBytes = await Printing.convertHtml(html: invoiceHtml);

      // Print the invoice
      await Printing.layoutPdf(
        onLayout: (format) {
          return pdfBytes;
        },
        name: name,
      );
    } catch (e) {
      throw Exception('Failed to print invoice: $e');
    }
  }
}
