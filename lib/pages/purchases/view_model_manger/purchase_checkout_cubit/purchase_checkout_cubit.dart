
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos_final/apis/purchases.dart';
import 'package:pos_final/config.dart';
import 'package:pos_final/helpers/api_handler/api_response.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/product_item_model.dart';
import 'package:pos_final/models/system.dart';
import 'package:pos_final/pages/purchases/parameters_model/add_purchase_parameters.dart';

part 'purchase_checkout_state.dart';

class PurchaseCheckoutCubit extends Cubit<PurchaseCheckoutState> {
  PurchaseCheckoutCubit(this._context) : super(PurchaseCheckoutInitial());

  //#region Private Variables
  final TextEditingController _paymentDateController = TextEditingController();
  final TextEditingController _paymentAmountController =
  TextEditingController();
  final TextEditingController _chequeNumberController = TextEditingController();
  final TextEditingController _bankAccountNumberController =
  TextEditingController();

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderNameController =
  TextEditingController();
  final TextEditingController _cardSecurityCodeController =
  TextEditingController();
  final TextEditingController _cardExpiryMonthController =
  TextEditingController();
  final TextEditingController _cardExpiryYearController =
  TextEditingController();

  String? _cardType;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late PurchasesParameters _purchasesParameters;

  final BuildContext _context;

  //#endregion

  set purchaseParameters(PurchasesParameters purchasesParameters) =>
      _purchasesParameters = purchasesParameters;

  PaymentWay paymentWay = PaymentWay.none;

  //#region Getters
  TextEditingController get cardNumberController => _cardNumberController;

  TextEditingController get cardHolderNameController =>
      _cardHolderNameController;

  TextEditingController get cardSecurityCodeController =>
      _cardSecurityCodeController;

  TextEditingController get cardExpiryMonthController =>
      _cardExpiryMonthController;

  TextEditingController get cardExpiryYearController =>
      _cardExpiryYearController;

  TextEditingController get paymentDateController => _paymentDateController;

  TextEditingController get paymentAmountController => _paymentAmountController;

  TextEditingController get chequeNumberController => _chequeNumberController;

  TextEditingController get bankAccountNumberController =>
      _bankAccountNumberController;

  GlobalKey<FormState> get formKey => _formKey;

  //#endregion

  //#region Public Methods
  List<List<String>> makeTableCells(Map<Data, int> products) {
    var keys = products.keys.toList(), values = products.values.toList();
    return List.generate(products.entries.length, (index) {
      num price = num.parse(keys[index]
          .productVariations![0]
          .variations![0]
          .defaultPurchasePrice!);
      return [
        keys[index].name!,
        values[index].toString(),
        price.toString(),
        (price * values[index]).toString()
      ];
    });
  }

  List<String> makeTableColumns(BuildContext context) {
    return [
      AppLocalizations.of(context).translate('product'),
      AppLocalizations.of(context).translate('quantity'),
      AppLocalizations.of(context).translate('price'),
      AppLocalizations.of(context).translate('total'),
    ];
  }

  List<DropdownMenuItem<PaymentWay>> paymentItems(BuildContext context) {
    return List.generate(
        PaymentWay.values.length,
            (index) => DropdownMenuItem(
          value: PaymentWay.values[index],
          child: Text(AppLocalizations.of(context)
              .translate(PaymentWay.values[index].name.toLowerCase())),
        ));
  }

  void selectPaymentWay(PaymentWay? value) {
    paymentWay = value!;
    emit(PurchaseCheckoutChangePayment());
  }

  void onDateTimeChanged(DateTime dateTime) {
    _paymentDateController.text = dateTime.toString();
  }

  void onCardTypeChange(String? value) {
    _cardType = value;
  }

  void checkOutPressed() async {
    if (_formKey.currentState!.validate()) {
      await _checkOut();
      if (state is! CheckOutFailedState) {
        Navigator.pushNamed(_context, '/layout');
      }
    }
  }

  //#endregion

  //#region Private Methods
  Future<void> _checkOut() async {
    emit(CheckOutLoadingState());
    PurchasesService purchasesService = PurchasesService();
    Map<String, dynamic> purchaseParameters = await _makeCheckoutParameters();
    ApiResponse apiResponse =
        await purchasesService.addPurchases(purchaseParameters);
    if (apiResponse.response?.statusCode == 200 &&
        apiResponse.response?.data != null) {
      if (apiResponse.response!.data['output']['success'] == 1) {
        emit(CheckOutSuccessState());
      } else {
        emit(CheckOutFailedState());
      }
    } else {
      emit(CheckOutFailedState());
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MM/dd/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  String _getPaymentDate() {
    if (_paymentDateController.text.isEmpty) {
      return _formatDateTime(DateTime.now());
    }
    return _formatDateTime(DateTime.parse(_paymentDateController.text));
  }

  Map<String, dynamic> _setPaymentData() {
    Map<String, dynamic> returnedMap = {
      'amount': _paymentAmountController.text.isEmpty
          ? 0.0
          : _paymentAmountController.text,
      'paid_on': _getPaymentDate(),
      'card_type': 'credit',
      'method': ''
    };

    switch (paymentWay) {
      case PaymentWay.none:
        returnedMap = {
          'amount': 0.0,
          'paid_on': _getPaymentDate(),
          'card_type': 'credit',
          'method': 'cash'
        };
      case PaymentWay.cash:
        returnedMap['method'] = PaymentWay.cash.name.toLowerCase();
      case PaymentWay.advance:
        returnedMap['method'] = PaymentWay.advance.name.toLowerCase();
      case PaymentWay.cheque:
        returnedMap['method'] = PaymentWay.cheque.name.toLowerCase();
        returnedMap['cheque_number'] = _chequeNumberController.text;

      case PaymentWay.bankTransfer:
        returnedMap['method'] = 'bank_transfer';
        returnedMap['bank_account_number'] = _bankAccountNumberController.text;
      case PaymentWay.card:
        returnedMap['card'] = 'bank_transfer';
        returnedMap['card_number'] = _cardNumberController.text;
        returnedMap['card_holder_name'] = _cardHolderNameController.text;
        returnedMap['card_month'] = _cardExpiryMonthController.text;
        returnedMap['card_year'] = _cardExpiryYearController.text;
        returnedMap['card_security'] = _cardSecurityCodeController.text;
        returnedMap['card_type'] = _cardType ?? 'credit';
    }

    return returnedMap;
  }

  Future<Map<String, dynamic>> _makeCheckoutParameters() async {
    final String userId = Config.userId!.toString();
    final String businessId = await _getBusinessId();
    List<Map<String, dynamic>> purchases = _reformatProducts();
    Map<String, dynamic> paymentMap = _setPaymentData();
    double purchaseTotal = _calcPurchaseTotal();
    Map<String, dynamic> purchaseParameters = {
      'discount_type': _purchasesParameters.discountType ?? '',
      'tax_amount': 0.0,
      'shipping_charges': _purchasesParameters.shippingCharge ?? 0.0,
      'business_id': businessId,
      'user_id': userId,
      'status': _purchasesParameters.purchaseState,
      'contact_id': _purchasesParameters.supplierId,
      'total_before_tax': purchaseTotal,
      'location_id': _purchasesParameters.locationId,
      'final_total': purchaseTotal,
      'exchange_rate': 1,
      'transaction_date': _formatDateTime(DateTime.now()),
      'purchases': purchases,
      'payment': [paymentMap]
    };
    return purchaseParameters;
  }

  Future<String> _getBusinessId() async {
    List business = await System().get('business');
    return business[0]['id'].toString();
  }

  double _calcPurchaseTotal() {
    Map<Data, int> products = _purchasesParameters.products!;
    double total = 0;
    for (int i = 0; i < products.length; i++) {
      var product = products.keys.toList()[i];
      double productPrice = double.parse(
          product.productVariations![0].variations![0].defaultSellPrice!);
      int quantity = products.values.toList()[i];
      total += (productPrice * quantity);
    }
    return total;
  }

  List<Map<String, dynamic>> _reformatProducts() {
    Map<Data, int> products = _purchasesParameters.products!;
    List<Map<String, dynamic>> data = [];
    for (int i = 0; i < products.length; i++) {
      var product = products.keys.toList()[i];
      data.add({
        "product_id": product.id,
        "variation_id": product.productVariations![0].variations![0].id,
        "quantity": products.values.toList()[i],
        "product_unit_id": product.unit!.id!,
        "sub_unit_id": product.subCategory?.id ?? 0,
        'pp_without_discount': double.parse(
            product.productVariations![0].variations![0].defaultPurchasePrice!),
        'discount_percent': _purchasesParameters.discountAmount ?? 0.0,
        'purchase_price': double.parse(
            product.productVariations![0].variations![0].defaultPurchasePrice!),
        'purchase_line_tax_id': '',
        'item_tax': 0.0,
        'purchase_price_inc_tax': double.parse(
            product.productVariations![0].variations![0].dppIncTax!),
        'profit_percent': double.parse(
            product.productVariations![0].variations![0].profitPercent!),
        'default_sell_price': double.parse(
            product.productVariations![0].variations![0].defaultSellPrice!)
      });
    }
    return data;
  }
//#endregion
}

enum PaymentWay { none, cash, advance, cheque, bankTransfer, card }

enum CardTypes { credit, debit, visa, masterCard }
