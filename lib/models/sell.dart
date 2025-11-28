import 'dart:convert';

import '../apis/sell.dart';
import '../models/payment_database.dart';
import '../models/sell_database.dart';
import '../models/system.dart';

class Sell {
  // Sync sell with API
  Future<bool> createApiSell({int? sellId, bool? syncAll}) async {
    List sales;
    if (syncAll != null) {
      sales = await SellDatabase().getNotSyncedSells();
    } else {
      sales = await SellDatabase().getSellBySellId(sellId);
    }
    for (var element in sales) {
      List products = await SellDatabase().getSellLines(element['id']);
      List<Map<String, dynamic>> formattedProducts = products.map((p) => {
        'product_id': p['product_id'],
        'variation_id': p['variation_id'],
        'quantity': p['quantity'],
        'unit_price': p['unit_price'],
        'tax_rate_id': p['tax_rate_id'],
        'discount_amount': p['discount_amount'] ?? 0.0,
        'discount_type': p['discount_type'] ?? 'fixed',
      }).toList();

      // Model map for creating new sell
      List<Map<String, dynamic>> sale = [
        {
          'location_id': element['location_id'],
          'contact_id': element['contact_id'],
          'transaction_date': element['transaction_date'],
          'invoice_no': element['invoice_no'],
          'status': element['status'],
          'sub_status': element['is_quotation'] == 1 ? 'quotation' : null,
          'tax_rate_id': element['tax_rate_id'] == 0 ? null : element['tax_rate_id'],
          'discount_amount': element['discount_amount'] ?? 0.0,
          'discount_type': element['discount_type'] ?? 'fixed',
          'change_return': element['change_return'] ?? 0.0,
          'products': formattedProducts,
          'sale_note': element['sale_note'],
          'staff_note': element['staff_note'],
          'shipping_charges': 0.0,
          'shipping_details': null,
          'shipping_address': null,
          'shipping_status': null,
          'delivered_to': null,
          'is_quotation': element['is_quotation'] ?? 0,
          'is_suspend': element['is_suspend'] ?? 0,
          'payments': await PaymentDatabase().get(element['id']),
        }
      ];

      // Fetch paymentLine where is_return = 1
      List paymentDetail = await PaymentDatabase().getPaymentLineByReturnValue(element['id'], 1);
      var returnId = paymentDetail.isNotEmpty ? paymentDetail[0]['payment_id'] : null;

      // Model map for updating an existing sell
      Map<String, dynamic> editedSale = {
        'contact_id': element['contact_id'],
        'transaction_date': element['transaction_date'],
        'status': element['status'],
        'tax_rate_id': element['tax_rate_id'] == 0 ? null : element['tax_rate_id'],
        'discount_amount': element['discount_amount'] ?? 0.0,
        'discount_type': element['discount_type'] ?? 'fixed',
        'sale_note': element['sale_note'],
        'staff_note': element['staff_note'],
        'shipping_charges': 0.0,
        'shipping_details': null,
        'shipping_address': null,
        'shipping_status': null,
        'delivered_to': null,
        'is_quotation': element['is_quotation'] ?? 0,
        'is_suspend': element['is_suspend'] ?? 0,
        'change_return': element['change_return'] ?? 0.0,
        'change_return_id': returnId,
        'products': formattedProducts,
        'payments': await PaymentDatabase().getPaymentLineByReturnValue(element['id'], 0),
      };

      if (element['is_synced'] == 0) {
        if (element['transaction_id'] != null) {
          var sell = jsonEncode(editedSale);
          Map<String, dynamic> updatedResult = await SellApi().update(element['transaction_id'], sell);
          if (!updatedResult.containsKey('error')) {
            await SellDatabase().updateSells(element['id'], {
              'is_synced': 1,
              'invoice_url': updatedResult['invoice_url'],
              'status': updatedResult['status'],
              'is_quotation': updatedResult['is_quotation'],
              'is_suspend': updatedResult['is_suspend'],
            });
            // Delete existing payment lines
            await PaymentDatabase().delete(element['id']);
            updatedResult['payment_lines'].forEach((paymentLine) async {
              await PaymentDatabase().store({
                'sell_id': element['id'],
                'method': paymentLine['method'],
                'amount': paymentLine['amount'],
                'note': paymentLine['note'],
                'payment_id': paymentLine['id'],
                'is_return': paymentLine['is_return'] ?? 0,
                'account_id': paymentLine['account_id'],
                'card_number': paymentLine['card_number'],
                'card_type': paymentLine['card_type'],
                'card_holder_name': paymentLine['card_holder_name'],
              });
            });
          }
        } else {
          var sell = jsonEncode({'sells': sale});
          var result = await SellApi().create(sell);
          if (!result.containsKey('error')) {
            await SellDatabase().updateSells(element['id'], {
              'is_synced': 1,
              'transaction_id': result['transaction_id'],
              'invoice_url': result['invoice_url'],
              'status': result['status'],
              'is_quotation': result['is_quotation'],
              'is_suspend': result['is_suspend'],
            });
            if (result['payment_lines'] != null) {
              await PaymentDatabase().delete(element['id']);
              result['payment_lines'].forEach((paymentLine) async {
                await PaymentDatabase().store({
                  'sell_id': element['id'],
                  'method': paymentLine['method'],
                  'amount': paymentLine['amount'],
                  'note': paymentLine['note'],
                  'payment_id': paymentLine['id'],
                  'is_return': paymentLine['is_return'] ?? 0,
                  'account_id': paymentLine['account_id'],
                  'card_number': paymentLine['card_number'],
                  'card_type': paymentLine['card_type'],
                  'card_holder_name': paymentLine['card_holder_name'],
                });
              });
            }
          }
        }
      }
    }
    return true;
  }

  // Delete a sell
  Future<bool> delete(int transactionId) async {
    var result = await SellApi().delete(transactionId);
    return !result.containsKey('error');
  }

  // Create payment
  Future<void> makePayment(List payments, int sellId) async {
    for (var element in payments) {
      Map<String, dynamic> payment = {
        'sell_id': sellId,
        'method': element['payment_method'] ?? element['method'],
        'amount': element['amount'],
        'note': element['note'] ?? '',
        'account_id': element['account_id'],
        'transaction_date': element['transaction_date'],
        'is_return': element['is_return'] ?? 0,
        'card_number': element['card_number'],
        'card_type': element['card_type'],
        'card_holder_name': element['card_holder_name'],
      };
      await PaymentDatabase().store(payment);
    }
  }

  // Create sell
  Future<Map<String, dynamic>> createSell({
    String? invoiceNo,
    String? transactionDate,
    int? contactId,
    int? locId,
    int? taxId,
    String? discountType,
    double? discountAmount,
    double? invoiceAmount,
    double? changeReturn,
    double? pending,
    String? saleNote,
    String? staffNote,
    double? shippingCharges,
    String? shippingDetails,
    String? shippingAddress,
    String? shippingStatus,
    String? deliveredTo,
    String? saleStatus,
    int? isQuotation,
    int? isSuspend,
    int? sellId,
  }) async {
    Map<String, dynamic> sale;
    if (sellId == null) {
      sale = {
        'transaction_date': transactionDate,
        'invoice_no': invoiceNo,
        'contact_id': contactId,
        'location_id': locId,
        'status': saleStatus ?? 'final',
        'tax_rate_id': taxId,
        'discount_amount': discountAmount ?? 0.0,
        'discount_type': discountType ?? 'fixed',
        'invoice_amount': invoiceAmount ?? 0.0,
        'change_return': changeReturn ?? 0.0,
        'sale_note': saleNote,
        'staff_note': staffNote,
        'shipping_charges': 0.0,
        'shipping_details': null,
        'shipping_address': null,
        'shipping_status': null,
        'delivered_to': null,
        'pending_amount': pending ?? 0.0,
        'is_quotation': isQuotation ?? 0,
        'is_suspend': isSuspend ?? 0,
        'is_synced': 0,
      };
    } else {
      sale = {
        'contact_id': contactId,
        'transaction_date': transactionDate,
        'location_id': locId,
        'status': saleStatus ?? 'final',
        'tax_rate_id': taxId,
        'discount_amount': discountAmount ?? 0.0,
        'discount_type': discountType ?? 'fixed',
        'invoice_amount': invoiceAmount ?? 0.0,
        'change_return': changeReturn ?? 0.0,
        'sale_note': saleNote,
        'staff_note': staffNote,
        'shipping_charges': 0.0,
        'shipping_details': null,
        'shipping_address': null,
        'shipping_status': null,
        'delivered_to': null,
        'pending_amount': pending ?? 0.0,
        'is_quotation': isQuotation ?? 0,
        'is_suspend': isSuspend ?? 0,
        'is_synced': 0,
      };
    }
    return sale;
  }

  // Get unit price (excluding tax)
  Future<double> getUnitPrice(double unitPrice, int? taxId) async {
    if (taxId == null || taxId == 0) return unitPrice;
    double price = unitPrice;
    await System().get('tax').then((value) {
      for (var element in value) {
        if (element['id'] == taxId) {
          price = (unitPrice * 100) / (double.parse(element['amount'].toString()) + 100);
        }
      }
    });
    return price;
  }

  // Create sell line
  Future<void> addToCart(Map<String, dynamic> product, int sellId) async {
    double price = (product['tax_rate_id'] != null && product['tax_rate_id'] != 0)
        ? await getUnitPrice(double.parse(product['unit_price'].toString()), product['tax_rate_id'])
        : double.parse(product['unit_price'].toString());

    var sellLine = {
      'sell_id': sellId,
      'product_id': product['product_id'],
      'variation_id': product['variation_id'],
      'quantity': product['quantity'] ?? 1,
      'unit_price': price,
      'tax_rate_id': product['tax_rate_id'] == 0 ? null : product['tax_rate_id'],
      'discount_amount': product['discount_amount'] ?? 0.0,
      'discount_type': product['discount_type'] ?? 'fixed',
      'note': product['note'] ?? '',
      'is_completed': product['is_completed'] ?? 0,
    };

    List checkSellLine = await SellDatabase().checkSellLine(sellLine['variation_id'], sellId: sellId);
    if (checkSellLine.isNotEmpty) {
      var quantity = (checkSellLine[0]['quantity'] ?? 0) + (product['quantity'] ?? 1);
      await SellDatabase().update(checkSellLine[0]['id'], {
        'quantity': quantity,
        'discount_amount': product['discount_amount'] ?? 0.0,
        'discount_type': product['discount_type'] ?? 'fixed',
      });
    } else {
      await SellDatabase().store(sellLine);
    }
  }

  // Reset cart
  Future<void> resetCart() async {
    await SellDatabase().deleteInComplete();
  }

  // Get cart item count
  Future<String> cartItemCount({bool? isCompleted, int? sellId}) async {
    return await SellDatabase().countSellLines(isCompleted: isCompleted, sellId: sellId);
  }

  // Refresh sale
  Map<String, dynamic> createSellMap(Map sell, double? change, double? pending) {
    return {
      'transaction_date': sell['transaction_date'],
      'invoice_no': sell['invoice_no'],
      'contact_id': sell['contact_id'],
      'location_id': sell['location_id'],
      'status': sell['status'],
      'tax_rate_id': sell['tax_id'] != 0 ? sell['tax_id'] : null,
      'discount_amount': sell['discount_amount'] ?? 0.0,
      'discount_type': sell['discount_type'] ?? 'fixed',
      'invoice_amount': sell['final_total'] ?? 0.0,
      'change_return': change ?? 0.0,
      'sale_note': sell['additional_notes'],
      'staff_note': sell['staff_note'],
      'shipping_charges': 0.0,
      'shipping_details': null,
      'shipping_address': null,
      'shipping_status': null,
      'delivered_to': null,
      'pending_amount': pending ?? 0.0,
      'is_quotation': sell['is_quotation'] ?? 0,
      'is_suspend': sell['is_suspend'] ?? 0,
      'is_synced': 1,
    };
  }
}