import 'dart:io';
import 'dart:math';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cron/cron.dart';
import 'package:flutter/material.dart';
import 'package:htmltopdfwidgets/htmltopdfwidgets.dart' as pd;
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config/di.dart';
import '../config.dart';
import '../locale/my_localizations.dart';
import '../models/invoice.dart';
import '../models/sell_database.dart';
import '../models/system.dart';
import 'app_theme.dart';
import 'size_config.dart';
import 'package:domain/domain.dart';

class Helper {
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  Widget loadingIndicator(context) {
    return Center(
      child: Card(
        elevation: MySize.size10,
        child: Container(
          padding: EdgeInsets.all(MySize.size28!),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MySize.size8!),
          ),
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }

  // Format currency
  String formatCurrency(amount) {
    double convertAmount = double.tryParse(amount.toString()) ?? 0.0;
    var amt = NumberFormat.currency(
        symbol: '', decimalDigits: 0)
        .format(convertAmount);
    return amt;
  }

  // Validate input
  double validateInput(String val) {
    try {
      double value = double.parse(val.toString());
      return value;
    } catch (e) {
      return 0.00;
    }
  }

  // Format quantity
  String formatQuantity(amount) {
    if (amount == '-') return '-';
    double quantity = double.tryParse(amount.toString()) ?? 0.0;
    var amt = NumberFormat.currency(
        symbol: '', decimalDigits: Config.quantityPrecision)
        .format(quantity);
    return amt;
  }

  // Argument model
  Map argument({
    int? sellId,
    int? locId,
    int? taxId,
    String? discountType,
    double? discountAmount,
    double? invoiceAmount,
    int? customerId,
    int? isQuotation,
    int? isSuspend,
    double? shippingCharges,
    String? shippingDetails,
    String? shippingAddress,
    String? shippingStatus,
    String? deliveredTo,
  }) {
    Map args = {
      'sellId': sellId,
      'locationId': locId,
      'taxId': taxId,
      'discountType': discountType,
      'discountAmount': discountAmount,
      'invoiceAmount': invoiceAmount,
      'customerId': customerId,
      'is_quotation': isQuotation,
      'is_suspend': isSuspend,
      'shipping_charges': shippingCharges,
      'shipping_details': shippingDetails,
      'shipping_address': shippingAddress,
      'shipping_status': shippingStatus,
      'delivered_to': deliveredTo,
    };
    return args;
  }

  // Check internet connectivity with enhanced reliability
  Future<bool> checkConnectivity() async {
    try {
      List<ConnectivityResult> connectivityResult =
      await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi) ||
          connectivityResult.contains(ConnectivityResult.ethernet)) {
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(Duration(seconds: 5));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
          return false;
        } catch (_) {
          return false;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Get location name by location_id
  Future<String?> getLocationNameById(var id) async {
    String? locationName;
    var response = await System().get('location');
    for (var element in response) {
      if (element['id'] == int.tryParse(id.toString())) {
        locationName = element['name'];
        break;
      }
    }
    return locationName;
  }

  // Calculate inline tax and discount amount
  Future<Map<String, double>> calculateTaxAndDiscount({
    double? discountAmount,
    String? discountType,
    int? taxId,
    double? unitPrice,
    double? quantity,
  }) async {
    double disAmt = 0.0, tax = 0.00, taxAmt = 0.00;
    
    // Get tax from repository using new architecture
    if (taxId != null && taxId != 0) {
      try {
        final taxRepository = sl.get<TaxRepository>();
        final taxResult = await taxRepository.getTaxById(taxId);
        final taxFound = taxResult.fold(
          onSuccess: (taxEntity) {
            tax = taxEntity.amount;
            return true;
          },
          onError: (_) => false,
        );
        
        // Fallback to old System().get('tax') if repository fails
        if (!taxFound) {
          final value = await System().get('tax');
          for (var element in value) {
            if (element['id'] == taxId) {
              tax = double.tryParse(element['amount'].toString()) ?? 0.0;
              break;
            }
          }
        }
      } catch (e) {
        // Fallback to old System().get('tax') if repository not available
        final value = await System().get('tax');
        for (var element in value) {
          if (element['id'] == taxId) {
            tax = double.tryParse(element['amount'].toString()) ?? 0.0;
            break;
          }
        }
      }
    }

    double totalPrice = (unitPrice ?? 0.0) * (quantity ?? 1.0);
    if (discountType == 'fixed') {
      disAmt = (discountAmount ?? 0.0);
      taxAmt = (totalPrice - disAmt) * tax / 100;
    } else {
      disAmt = (totalPrice * (discountAmount ?? 0.0) / 100);
      taxAmt = (totalPrice - disAmt) * tax / 100;
    }
    return {'discountAmount': disAmt, 'taxAmount': taxAmt};
  }

  // Calculate price including tax
  Future<String> calculateTotal({
    double? unitPrice,
    String? discountType,
    double? discountAmount,
    int? taxId,
    double? quantity,
  }) async {
    double tax = 0.00;
    double subTotal = 0.00;
    double amount = 0.0;
    unitPrice = double.tryParse(unitPrice?.toString() ?? '0.0') ?? 0.0;
    discountAmount = double.tryParse(discountAmount?.toString() ?? '0.0') ?? 0.0;
    quantity = double.tryParse(quantity?.toString() ?? '1.0') ?? 1.0;

    // Get tax from repository using new architecture
    if (taxId != null && taxId != 0) {
      try {
        final taxRepository = sl.get<TaxRepository>();
        final taxResult = await taxRepository.getTaxById(taxId);
        final taxFound = taxResult.fold(
          onSuccess: (taxEntity) {
            tax = taxEntity.amount;
            return true;
          },
          onError: (_) => false,
        );
        
        // Fallback to old System().get('tax') if repository fails
        if (!taxFound) {
          final value = await System().get('tax');
          for (var element in value) {
            if (element['id'] == taxId) {
              tax = double.tryParse(element['amount'].toString()) ?? 0.0;
              break;
            }
          }
        }
      } catch (e) {
        // Fallback to old System().get('tax') if repository not available
        final value = await System().get('tax');
        for (var element in value) {
          if (element['id'] == taxId) {
            tax = double.tryParse(element['amount'].toString()) ?? 0.0;
            break;
          }
        }
      }
    }

    double totalPrice = unitPrice * quantity;
    if (discountType == 'fixed') {
      amount = totalPrice - discountAmount;
    } else {
      amount = totalPrice - (totalPrice * discountAmount / 100);
    }
    subTotal = (amount + (amount * tax / 100));
    return subTotal.toStringAsFixed(2);
  }

  // Barcode scan
  Future<String> barcodeScan() async {
    try {
      var result = await BarcodeScanner.scan();
      return result.rawContent.trimRight();
    } catch (e) {
      throw Exception('Failed to scan barcode: $e');
    }
  }

  // Print document
  Future<void> printDocument(int sellId, int? taxId, BuildContext context,
      {String? invoice}) async {
    final sell = await SellDatabase().getSellBySellId(sellId);
    if (sell.isEmpty) {
      throw Exception('Sale not found');
    }
    final sellData = sell[0];
    String invoice0 = invoice ??
        await InvoiceFormatter().generateInvoice(sellId, taxId, context);

    // Append additional fields to invoice HTML
    StringBuffer additionalInfo = StringBuffer();
    if (sellData['status'] != null) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('invoice_status')}:</strong> ${AppLocalizations.of(context).translate(sellData['status'])}</p>');
    }
    if (sellData['is_quotation'] == 1) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('quotation')}:</strong> ${AppLocalizations.of(context).translate('yes')}</p>');
    }
    if (sellData['is_suspend'] == 1) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('suspended')}:</strong> ${AppLocalizations.of(context).translate('yes')}</p>');
    }
    if (sellData['shipping_charges'] != null && sellData['shipping_charges'] > 0) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('shipping_charges')}:</strong> ${formatCurrency(sellData['shipping_charges'])}</p>');
    }
    if (sellData['shipping_details'] != null && sellData['shipping_details'].isNotEmpty) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('shipping_details')}:</strong> ${sellData['shipping_details']}</p>');
    }
    if (sellData['shipping_address'] != null && sellData['shipping_address'].isNotEmpty) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('shipping_address')}:</strong> ${sellData['shipping_address']}</p>');
    }
    if (sellData['shipping_status'] != null && sellData['shipping_status'].isNotEmpty) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('shipping_status')}:</strong> ${AppLocalizations.of(context).translate(sellData['shipping_status'].toLowerCase())}</p>');
    }
    if (sellData['delivered_to'] != null && sellData['delivered_to'].isNotEmpty) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('delivered_to')}:</strong> ${sellData['delivered_to']}</p>');
    }

    // Insert additional info into the invoice HTML
    invoice0 = invoice0.replaceFirst('</body>', '$additionalInfo</body>');

    await Printing.layoutPdf(onLayout: (pd.PdfPageFormat format) async {
      return await Printing.convertHtml(
        format: format,
        html: invoice0,
      );
    });
  }

  // Request permissions
  Future<Map<Permission, PermissionStatus>> requestAppPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.storage,
      Permission.camera,
    ].request();
    return statuses;
  }

  // Job scheduler for periodic tasks
  jobScheduler() {
    if (Config().syncCallLog) {
      final cron = Cron();
      cron.schedule(Schedule.parse('*/${Config.callLogSyncDuration} * * * *'),
              () async {
            await syncCallLogs();
          });
    }
  }

  // Post call_logs in API
  syncCallLogs() async {
    if (await Permission.phone.status == PermissionStatus.granted) {
      if (Config().syncCallLog && await checkConnectivity()) {
        List recentLogs = [];
        var lastSync = await System().callLogLastSyncDateTime();
        int getLogBefore = (lastSync != null)
            ? DateTime.now().difference(DateTime.parse(lastSync)).inMinutes
            : 1440;
        // int from = DateTime.now()
        //     .subtract(Duration(minutes: (getLogBefore > 1440) ? 1440 : getLogBefore))
        //     .millisecondsSinceEpoch;
        // try {
        //   await CallLog.query(dateFrom: from).then((value) async {
        //     if (value.isNotEmpty) {
        //       for (var element in value) {
        //         recentLogs.add(CallLogModel().createLog(element));
        //       }
        //       await FollowUpApi()
        //           .syncCallLog({'call_logs': recentLogs}).then((value) async {
        //         if (value == true) {
        //           await System().callLogLastSyncDateTime(true);
        //         }
        //       });
        //     }
        //   });
        // } catch (_) {}
      }
    }
  }

  // Save PDF
  Future<void> savePdf(int sellId, int? taxId, BuildContext context,
      String invoiceNo, {String? invoice}) async {
    final sell = await SellDatabase().getSellBySellId(sellId);
    if (sell.isEmpty) {
      throw Exception('Sale not found');
    }
    final sellData = sell[0];
    String invoice0 = invoice ??
        await InvoiceFormatter().generateInvoice(sellId, taxId, context);

    // Append additional fields to invoice HTML
    StringBuffer additionalInfo = StringBuffer();
    if (sellData['status'] != null) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('invoice_status')}:</strong> ${AppLocalizations.of(context).translate(sellData['status'])}</p>');
    }
    if (sellData['is_quotation'] == 1) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('quotation')}:</strong> ${AppLocalizations.of(context).translate('yes')}</p>');
    }
    if (sellData['is_suspend'] == 1) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('suspended')}:</strong> ${AppLocalizations.of(context).translate('yes')}</p>');
    }
    if (sellData['shipping_charges'] != null && sellData['shipping_charges'] > 0) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('shipping_charges')}:</strong> ${formatCurrency(sellData['shipping_charges'])}</p>');
    }
    if (sellData['shipping_details'] != null && sellData['shipping_details'].isNotEmpty) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('shipping_details')}:</strong> ${sellData['shipping_details']}</p>');
    }
    if (sellData['shipping_address'] != null && sellData['shipping_address'].isNotEmpty) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('shipping_address')}:</strong> ${sellData['shipping_address']}</p>');
    }
    if (sellData['shipping_status'] != null && sellData['shipping_status'].isNotEmpty) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('shipping_status')}:</strong> ${AppLocalizations.of(context).translate(sellData['shipping_status'].toLowerCase())}</p>');
    }
    if (sellData['delivered_to'] != null && sellData['delivered_to'].isNotEmpty) {
      additionalInfo.write('<p><strong>${AppLocalizations.of(context).translate('delivered_to')}:</strong> ${sellData['delivered_to']}</p>');
    }

    // Insert additional info into the invoice HTML
    invoice0 = invoice0.replaceFirst('</body>', '$additionalInfo</body>');

    var targetPath = await getTemporaryDirectory();
    var targetFileName = "invoice_no_${Random().nextInt(100)}.pdf";
    final String path = '${targetPath.path}/$targetFileName';
    const double cm = 28.346456692913385826771653543307;
    final pdfDocument = await Printing.convertHtml(
      format: const pd.PdfPageFormat(21 * cm, 29.7 * cm),
      html: invoice0,
    );
    await File(path).writeAsBytes(pdfDocument);
    await Printing.sharePdf(bytes: pdfDocument, filename: targetFileName);
  }

  // Fetch formatted business details
  Future<Map<String, dynamic>> getFormattedBusinessDetails() async {
    List business = await System().get('business');
    String? symbol = business[0]['currency']['symbol'],
        name = business[0]['name'],
        logo = business[0]['logo'],
        taxLabel = business[0]['tax_label_1'],
        taxNumber = business[0]['tax_number_1'];
    int? currencyPrecision = business[0]['currency_precision'],
        quantityPrecision = business[0]['quantity_precision'];
    return {
      'symbol': symbol ?? '',
      'name': name ?? '',
      'logo': logo ?? Config().defaultBusinessImage,
      'currencyPrecision': currencyPrecision ?? Config.currencyPrecision,
      'quantityPrecision': quantityPrecision ?? Config.quantityPrecision,
      'taxLabel': (taxLabel != null) ? '$taxLabel : ' : '',
      'taxNumber': (taxNumber != null) ? taxNumber : ''
    };
  }

  // Fetch advance balance for a customer
  Future<double> getAdvanceBalance(int? customerId) async {
    if (customerId == null) return 0.0;
    try {
      List customerData = await System().get('contact', customerId);
      if (customerData.isNotEmpty) {
        double advanceBalance = double.tryParse(customerData[0]['advance_balance']?.toString() ?? '0.0') ?? 0.0;
        return advanceBalance;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Fetch permission from database
  Future<bool> getPermission(String permissionFor) async {
    bool permission = false;
    await System().getPermission().then((value) {
      if (value[0] == 'all' || value.contains(permissionFor)) {
        permission = true;
      }
    });
    return permission;
  }

  // Call widget
  Widget callDropdown(BuildContext context, dynamic followUpDetails, List numbers,
      {required String type}) {
    numbers.removeWhere((element) => element.toString() == 'null');
    return SizedBox(
      height: MySize.size36,
      child: PopupMenuButton<String>(
        icon: Icon(
          (type == 'call') ? MdiIcons.phone : MdiIcons.whatsapp,
          color:
          (type == 'call') ? themeData.colorScheme.primary : Colors.green,
        ),
        onSelected: (value) async {
          if (type == 'call') {
            await launchUrl(Uri.parse('tel:$value'));
          }
          if (type == 'whatsApp') {
            await launchUrl(Uri.parse('https://wa.me/$value'));
          }
        },
        itemBuilder: (BuildContext context) {
          return numbers.map((item) {
            return PopupMenuItem<String>(
              value: item,
              child: Text(
                '$item',
                style: const TextStyle(color: Colors.black),
              ),
            );
          }).toList();
        },
      ),
    );
  }

  // No data widget
  Widget noDataWidget(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: CachedNetworkImage(
            imageUrl: Config().noDataImage,
            errorWidget: (context, url, error) =>
                Lottie.asset('assets/lottie/empty.json'),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            AppLocalizations.of(context).translate('no_data'),
            style: AppTheme.getTextStyle(
              themeData.textTheme.headlineSmall,
              fontWeight: 600,
              color: themeData.colorScheme.onSurface,
            ),
          ),
        )
      ],
    );
  }

  // Check if products need refresh
  Future<bool> needsProductRefresh() async {
    String? lastSync = await System().getProductLastSync();
    if (lastSync == null) return true;
    final date2 = DateTime.now();
    return date2.difference(DateTime.parse(lastSync)).inMinutes > 10;
  }

  // Check if customers need refresh
  Future<bool> needsCustomersRefresh() async {
    String? lastSync = await System().getCustomersLastSync();
    if (lastSync == null) return true;
    final date2 = DateTime.now();
    return date2.difference(DateTime.parse(lastSync)).inMinutes > 10;
  }
}