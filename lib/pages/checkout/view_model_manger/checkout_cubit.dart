import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pos_final/config.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/models/payment_database.dart';
import 'package:pos_final/models/sell.dart';
import 'package:pos_final/models/sell_database.dart';
import 'package:pos_final/models/system.dart';

part 'checkout_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit()
      : super(CheckoutState(
            transactionDate:
                DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())));

  void emitForTesting(CheckoutState state) {
    emit(state);
  }

  void init(Map arguments) async {
    emit(state.copyWith(isLoading: true));
    // Get business details for symbol
    final businessDetails = await Helper().getFormattedBusinessDetails();
    final symbol = businessDetails['symbol'];

    // Set invoice amount from arguments
    final invoiceAmount = arguments['invoiceAmount'];

    emit(state.copyWith(
        arguments: arguments,
        symbol: symbol,
        invoiceAmount: invoiceAmount,
        isLoading: true));

    await setPaymentAccounts(arguments['locationId']);

    emit(state.copyWith(isLoading: false));
  }

  Future<void> setPaymentAccounts(int locationId) async {
    // Get payment methods for location
    final payments = await System().get('payment_method', locationId);

    // Get all payment accounts
    final accounts = await System().getPaymentAccounts();

    List<Map<String, dynamic>> paymentAccounts = [
      {'id': null, 'name': "None"}
    ];
    List<Map<String, dynamic>> paymentMethods = [];

    // Map payment methods
    for (var method in payments) {
      paymentMethods.add({
        'name': method['name'],
        'value': method['label'],
        'account_id': method['account_id'] != null
            ? int.parse(method['account_id'].toString())
            : null
      });
    }

    // Map payment accounts that are assigned to payment methods
    for (var account in accounts) {
      for (var method in payments) {
        if (method['account_id'].toString() == account['id'].toString()) {
          paymentAccounts.add({'id': account['id'], 'name': account['name']});
          break;
        }
      }
    }

    emit(state.copyWith(
        paymentAccounts: paymentAccounts, paymentMethods: paymentMethods));

    // Add initial payment if no sell ID
    if (state.sellId == null) {
      addPayment(state.invoiceAmount, paymentMethods[0]['name'],
          paymentMethods[0]['account_id']);
    }
  }

  void addPayment(double amount, String method, int? accountId) {
    final List<Map<String, dynamic>> updatedPayments =
        List.from(state.payments);
    updatedPayments.add({
      'amount': amount,
      'method': method,
      'note': '',
      'account_id': accountId
    });
    emit(state.copyWith(payments: updatedPayments));
    calculateMultiPayment();
  }

  void removePayment(int index, int? paymentId) {
    final List<Map<String, dynamic>> updatedPayments =
        List.from(state.payments);
    final List<int> updatedDeletedIds = List.from(state.deletedPaymentIds);

    if (paymentId != null) {
      updatedDeletedIds.add(paymentId);
    }

    updatedPayments.removeAt(index);

    emit(state.copyWith(
        payments: updatedPayments, deletedPaymentIds: updatedDeletedIds));

    calculateMultiPayment();
  }

  void updatePaymentAmount(int index, String value) {
    final List<Map<String, dynamic>> updatedPayments =
        List.from(state.payments);
    updatedPayments[index]['amount'] = Helper().validateInput(value);

    emit(state.copyWith(payments: updatedPayments));
    calculateMultiPayment();
  }

  void updatePaymentMethod(int index, String method) {
    final List<Map<String, dynamic>> updatedPayments = List.from(
        state.payments.map((p) => Map<String, dynamic>.from(p)).toList());

    final selectedMethod = state.paymentMethods.firstWhere(
      (element) => element['name'].toString() == method,
      orElse: () => state.paymentMethods.first,
    );

    updatedPayments[index] = {
      ...updatedPayments[index],
      'method': method,
      'account_id': selectedMethod['account_id'],
    };

    emit(state.copyWith(payments: updatedPayments));
  }

  void updatePaymentAccount(int index, int accountId) {
    final List<Map<String, dynamic>> updatedPayments = List.from(
        state.payments.map((p) => Map<String, dynamic>.from(p)).toList());
    updatedPayments[index]['account_id'] = accountId;

    emit(state.copyWith(payments: updatedPayments));
  }

  void calculateMultiPayment() {
    double totalPaying = 0.0;

    for (var payment in state.payments) {
      totalPaying += payment['amount'];
    }

    double changeReturn = 0.0;
    double pendingAmount = 0.0;

    if (totalPaying > state.invoiceAmount) {
      changeReturn = totalPaying - state.invoiceAmount;
    } else if (state.invoiceAmount > totalPaying) {
      pendingAmount = state.invoiceAmount - totalPaying;
    }

    emit(state.copyWith(
        totalPaying: totalPaying,
        changeReturn: changeReturn,
        pendingAmount: pendingAmount));
  }

  void updateShippingCharges(String value) {
    final shippingCharges = Helper().validateInput(value);
    final newInvoiceAmount = state.invoiceAmount + shippingCharges;

    emit(state.copyWith(
        shippingCharges: shippingCharges, invoiceAmount: newInvoiceAmount));

    calculateMultiPayment();
  }

  void updateSellNote(String value) {
    emit(state.copyWith(sellNote: value));
  }

  void updateStaffNote(String value) {
    emit(state.copyWith(staffNote: value));
  }

  Future<void> updateInvoiceType(String type) async {
    final hasConnectivity = await Helper().checkConnectivity();
    if (type == "Web" && !hasConnectivity) return;

    emit(state.copyWith(invoiceType: type, printWebInvoice: type == "Web"));
  }

  void setPrintInvoice(bool value) {
    emit(state.copyWith(printInvoice: value));
  }

  Future<void> onSubmit() async {
    emit(state.copyWith(isLoading: true, saleCreated: true));
    Map arguments = state.arguments;
    try {
      // Create sell record
      final Map<String, dynamic> sellData = await Sell().createSell(
          invoiceNo:
              "${Config.userId}_${DateFormat('yMdHm').format(DateTime.now())}",
          transactionDate: state.transactionDate,
          changeReturn: state.changeReturn,
          contactId: arguments['customerId'],
          discountAmount: arguments['discountAmount'],
          discountType: arguments['discountType'],
          invoiceAmount: state.invoiceAmount,
          locId: arguments['locationId'],
          pending: state.pendingAmount,
          saleNote: state.saleNote,
          saleStatus: 'final',
          sellId: state.sellId,
          shippingCharges: state.shippingCharges ?? 0.00,
          shippingDetails: state.shippingDetails,
          staffNote: state.staffNote,
          taxId: arguments['taxId'],
          isQuotation: 0);

      int? responseId;

      if (state.sellId != null) {
        // Update existing sell
        await SellDatabase().updateSells(state.sellId!, sellData);
        responseId = state.sellId;

        // Handle payments
        for (var payment in state.payments) {
          if (payment['id'] != null) {
            // Update existing payment
            await PaymentDatabase().updateEditedPaymentLine(payment['id'], {
              'amount': payment['amount'],
              'method': payment['method'],
              'note': payment['note'],
              'account_id': payment['account_id']
            });
          } else {
            // Create new payment
            await PaymentDatabase().store({
              'sell_id': state.sellId,
              'method': payment['method'],
              'amount': payment['amount'],
              'note': payment['note'],
              'account_id': payment['account_id']
            });
          }
        }

        // Delete removed payments
        if (state.deletedPaymentIds.isNotEmpty) {
          await PaymentDatabase()
              .deletePaymentLineByIds(state.deletedPaymentIds);
        }
      }
      else {
        // Create new sell
        responseId = await SellDatabase().storeSell(sellData);

        // Create payments
        await Sell().makePayment(state.payments, responseId);

        // Update sell line
        await SellDatabase()
            .updateSellLine({'sell_id': responseId, 'is_completed': 1});
      }

      // Create API sell if online
      if (await Helper().checkConnectivity()) {
        await Sell().createApiSell(sellId: responseId);
      }

      emit(state.copyWith(sellId: responseId, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> printInvoice(BuildContext context) async {
    final sellId = state.sellId;
    final taxId = state.arguments['taxId'];
    try {
      final sellDetail = await SellDatabase().getSellBySellId(sellId);
      final String? invoiceUrl = sellDetail[0]['invoice_url'];
      final String invoiceNo = sellDetail[0]['invoice_no'];

      if (state.printInvoice) {
        if (state.printWebInvoice && invoiceUrl != null) {
          final response = await http.Client().get(Uri.parse(invoiceUrl));
          if (response.statusCode == 200) {
            await Helper()
                .printDocument(sellId!, taxId, context, invoice: response.body);
          } else {
            await Helper().printDocument(sellId!, taxId, context);
          }
        } else {
          await Helper().printDocument(sellId!, taxId, context);
        }
      } else {
        if (state.printWebInvoice && invoiceUrl != null) {
          final response = await http.Client().get(Uri.parse(invoiceUrl));
          if (response.statusCode == 200) {
            await Helper().savePdf(sellId!, taxId, context, invoiceNo,
                invoice: response.body);
          } else {
            await Helper().savePdf(sellId!, taxId, context, invoiceNo);
          }
        } else {
          await Helper().savePdf(sellId!, taxId, context, invoiceNo);
        }
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> finishInvoice(BuildContext context) async {
    await onSubmit();
    await printInvoice(context);
    Navigator.pushNamedAndRemoveUntil(
        context,
        (state.arguments['sellId'] == null) ? '/layout' : '/sale',
        ModalRoute.withName('/home'));
  }
}
