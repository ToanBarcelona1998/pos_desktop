import 'dart:async';
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/src/core/core.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../app_config/di.dart';

/// Print service for printing invoices
/// Handles invoice generation and printing
class PrintService {
  static late pw.Font robotoRegular;
  static late pw.Font robotoBold;

  static Future<void> init() async {
    robotoBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto_bold.ttf'),
    );
    robotoRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/roboto_regular.ttf'),
    );
  }

  static PdfPageFormat pos80 = PdfPageFormat(
    80 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 5 * PdfPageFormat.mm,
  );

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
    required String name,
    required String cashier,
    required String unit,
    required int locationId,
    required AppLocalizations l10n,
    required List<ProductEntity> products,
  }) async {
    try {
      final GetLayoutBillUseCase getLayoutBillUseCase =
          sl.get<GetLayoutBillUseCase>();

      final layoutBillResult = await getLayoutBillUseCase.call(
        GetLayoutBillParams(
          locationId: locationId,
        ),
      );

      LayoutBillEntity? billEntity;
      SellEntity? sellEntity;
      ContactEntity? contactEntity;

      billEntity = layoutBillResult.fold(
        onSuccess: (data) => data,
        onError: (error) => null,
      );

      final GetLocalSellsUseCase getLocalSellsUseCase =
          sl.get<GetLocalSellsUseCase>();

      final sellResult = await getLocalSellsUseCase.call();

      sellEntity = sellResult.fold(
          onSuccess: (sells) => sells.where((e) => e.id == sellId).firstOrNull,
          onError: (error) => null);

      final GetContactByIdUseCase getContactByIdUseCase =
          sl.get<GetContactByIdUseCase>();

      final contactId = sellEntity?.contactId;

      if (contactId != null) {
        final contactResult = await getContactByIdUseCase.call(contactId);

        contactResult.fold(
            onSuccess: (contact) => contactEntity = contact,
            onError: (error) {});
      }

      if (billEntity != null && sellEntity != null) {
        final Uint8List pdfBytes = await _buildPdf(
          products: products,
          layoutBill: billEntity,
          sell: sellEntity,
          contact: contactEntity,
          unit: unit,
          l10n: l10n,
          cashier: cashier,
        );

        // showDialog(
        //   context: context,
        //   builder: (ctx) => Dialog(
        //     child: PdfPreview(
        //       initialPageFormat: pos80,
        //       build: (format) => pdfBytes,
        //     ),
        //   ),
        // );

        final printers = await Printing.listPrinters();

        final printer = printers.firstWhere(
              (p) => p.isDefault,
          orElse: () => printers.first,
        );


        await Future.microtask(
          () => Printing.directPrintPdf(
            printer: printer,
            onLayout: (format) {
              return pdfBytes;
            },
            name: name,
          ),
        );
      }

      // Print the invoice
    } catch (e) {
      throw Exception('Failed to print invoice: $e');
    }
  }

  static Future<Uint8List> _buildPdf({
    required List<ProductEntity> products,
    required LayoutBillEntity layoutBill,
    required SellEntity sell,
    required String unit,
    required String cashier,
    ContactEntity? contact,
    required AppLocalizations l10n,
  }) {
    final LayoutBillLocationEntity locationEntity = layoutBill.location;
    final String address =
        '${locationEntity.name}, ${locationEntity.landmark ?? ''}, ${locationEntity.city ?? ''}, ${locationEntity.state ?? ''}, ${locationEntity.zipCode ?? ''}, ${locationEntity.country ?? ''}';

    final paymentLines = sell.payments;

    final pdf = pw.Document();

    final logoPath = layoutBill.business.cachedLogoPath;

    Uint8List? logoBytes;

    if (logoPath != null) {
      final logoFile = File(logoPath);

      logoBytes = logoFile.readAsBytesSync();
    }

    final double total = sell.sellLines.fold(0, (e, s) {
      final discountType = DiscountTypeExtension.fromString(s.discountType);

      double discount = 0;
      final quantity = s.quantity ?? 1;
      final unitPrice = s.unitPrice ?? 0;
      final subtotal = unitPrice * quantity;

      // Calculate discount based on type
      if (discountType == DiscountType.percentage) {
        discount = subtotal * (s.discountAmount ?? 0) / 100;
      } else if (discountType == DiscountType.fixed) {
        discount = (s.discountAmount ?? 0) * quantity;
      }

      final lineTotal = subtotal - discount;
      return e + lineTotal;
    });

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: robotoRegular,
          bold: robotoBold,
        ),
        pageFormat: pos80,
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoBytes != null)
                pw.Center(
                  child: pw.Image(pw.MemoryImage(logoBytes), height: 20),
                ),
              pw.SizedBox(height: 6),

              // STORE NAME
              pw.Center(
                child: pw.Text(
                  layoutBill.business.name,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.Center(
                child: pw.Text(
                  address,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ),

              pw.Center(
                child: pw.Text(
                  '${l10n.tr(LocaleKeys.billContact)}: ${locationEntity.mobile ?? ''}',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ),

              pw.SizedBox(height: 6),

              pw.Center(
                child: pw.Text(
                  l10n.tr(LocaleKeys.billTitle),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Center(
                child: _buildBarcode(sell.invoiceNo ?? ''),
              ),

              pw.SizedBox(height: 6),

              ///
              ///
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: '${l10n.tr(LocaleKeys.billId)}:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.TextSpan(
                          text: ' ${sell.invoiceNo ?? ''}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                            text: '${l10n.tr(LocaleKeys.billCustomer)}:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.TextSpan(
                          text: ' ${contact?.name ?? ''}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                            text: '${l10n.tr(LocaleKeys.billContact)}:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.TextSpan(
                          text: ' ${contact?.mobile ?? ''}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                            text: '${l10n.tr(LocaleKeys.billCashier)}:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.TextSpan(
                          text: ' $cashier',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                            text: '${l10n.tr(LocaleKeys.billDate)}:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                            )),
                        pw.TextSpan(
                          text:
                              ' ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.tryParse(sell.transactionDate ?? '') ?? DateTime.now())}',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              // TABLE ITEMS
              pw.Table(
                border: pw.TableBorder(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          l10n.tr(
                            LocaleKeys.billProduct,
                          ),
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          l10n.tr(LocaleKeys.billSL),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          l10n.tr(LocaleKeys.billPrice),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          l10n.tr(LocaleKeys.billTempPrice),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...sell.sellLines.map(
                    (e) {
                      final productId = e.productId;

                      final product = products
                          .where((p) => p.productId == productId)
                          .firstOrNull;

                      final discountType =
                          DiscountTypeExtension.fromString(e.discountType);

                      double discount = 0;
                      final quantity = e.quantity ?? 1;
                      final unitPrice = e.unitPrice ?? 0;
                      final subtotal = unitPrice * quantity;

                      // Calculate discount based on type
                      if (discountType == DiscountType.percentage) {
                        discount = subtotal * (e.discountAmount ?? 0) / 100;
                      } else if (discountType == DiscountType.fixed) {
                        discount = (e.discountAmount ?? 0) * quantity;
                      }

                      final lineTotal = subtotal - discount;

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              product?.productName ??
                                  product?.displayName ??
                                  '',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.normal,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              '${quantity.toInt()}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.normal,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              Helper().formatCurrency(unitPrice),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.normal,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Text(
                              Helper().formatCurrency(lineTotal),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                ],
              ),

              // SUMMARY
              pw.Table(
                children: [
                  _rowText(
                    '${l10n.tr(LocaleKeys.billSL)}:',
                    '${sell.sellLines.fold(0, (s, e) => (s + (e.quantity ?? 0)).toInt())}',
                  ),
                  _rowText(
                    '${l10n.tr(LocaleKeys.billTempPrice)}:',
                    '${Helper().formatCurrency(total)} $unit',
                  ),
                  _rowText(
                    '${l10n.tr(LocaleKeys.billTotal)}:',
                    '${Helper().formatCurrency(total)} $unit',
                  ),
                ],
              ),

              pw.SizedBox(height: 6),

              // PAYMENT
              pw.Table(
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 4),
                        child: pw.Text(
                          l10n.tr(LocaleKeys.billPayment),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...paymentLines.map((payment) => _rowText(
                        '${_getCashTranslate(payment.method ?? '', l10n: l10n)}:',
                        '${Helper().formatCurrency(payment.amount)} $unit',
                      )),
                ],
              ),

              pw.SizedBox(height: 12),

              pw.Center(
                child: pw.Text(
                  '${l10n.tr(LocaleKeys.billEnd)} ${locationEntity.name}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _rowText(String left, String right) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(left,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              )),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(
            right,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  static String _getCashTranslate(String paymentMethod,
      {required AppLocalizations l10n}) {
    final PaymentMethod paymentMethodEnum =
        PaymentMethodExtension.fromString(paymentMethod);

    switch (paymentMethodEnum) {
      case PaymentMethod.cash:
        return l10n.tr(LocaleKeys.billCash);
      case PaymentMethod.bankTransfer:
        return l10n.tr(LocaleKeys.billTransfer);
      case PaymentMethod.eWallet:
        return l10n.tr(LocaleKeys.billEWallet);
      default:
        return '';
    }
  }

  static pw.Widget _buildBarcode(String data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.BarcodeWidget(
          barcode: pw.Barcode.code128(),
          data: data,
          width: 70,
          height: 20,
          drawText: false,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          data,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
