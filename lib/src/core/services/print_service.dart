import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as pd;
import 'package:printing/printing.dart';

import '../../../models/invoice.dart';
import '../../../models/sell_database.dart';
import '../../../locale/my_localizations.dart';
import '../../../helpers/other_helpers.dart';

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
          onLayout: (pd.PdfPageFormat format) {
            return bytes;
          },
          name: name,
        );
      }
    } catch (e) {
      throw Exception('Failed to print invoice: $e');
    }
  }

  /// Build additional info HTML for invoice
  static String _buildAdditionalInfo(
    Map<String, dynamic> sellData,
    BuildContext context,
  ) {
    final buffer = StringBuffer();
    final l10n = AppLocalizations.of(context);

    if (sellData['status'] != null) {
      buffer.write(
        '<p><strong>${l10n.translate('invoice_status')}:</strong> ${l10n.translate(sellData['status'])}</p>',
      );
    }
    if (sellData['is_quotation'] == 1) {
      buffer.write(
        '<p><strong>${l10n.translate('quotation')}:</strong> ${l10n.translate('yes')}</p>',
      );
    }
    if (sellData['is_suspend'] == 1) {
      buffer.write(
        '<p><strong>${l10n.translate('suspended')}:</strong> ${l10n.translate('yes')}</p>',
      );
    }
    if (sellData['shipping_charges'] != null &&
        (sellData['shipping_charges'] as num) > 0) {
      buffer.write(
        '<p><strong>${l10n.translate('shipping_charges')}:</strong> ${Helper().formatCurrency(sellData['shipping_charges'])}</p>',
      );
    }
    if (sellData['shipping_details'] != null &&
        (sellData['shipping_details'] as String).isNotEmpty) {
      buffer.write(
        '<p><strong>${l10n.translate('shipping_details')}:</strong> ${sellData['shipping_details']}</p>',
      );
    }
    if (sellData['shipping_address'] != null &&
        (sellData['shipping_address'] as String).isNotEmpty) {
      buffer.write(
        '<p><strong>${l10n.translate('shipping_address')}:</strong> ${sellData['shipping_address']}</p>',
      );
    }
    if (sellData['shipping_status'] != null &&
        (sellData['shipping_status'] as String).isNotEmpty) {
      buffer.write(
        '<p><strong>${l10n.translate('shipping_status')}:</strong> ${l10n.translate((sellData['shipping_status'] as String).toLowerCase())}</p>',
      );
    }
    if (sellData['delivered_to'] != null &&
        (sellData['delivered_to'] as String).isNotEmpty) {
      buffer.write(
        '<p><strong>${l10n.translate('delivered_to')}:</strong> ${sellData['delivered_to']}</p>',
      );
    }

    return buffer.toString();
  }
}
