import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/apis/api.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/system.dart';
import 'package:pos_final/pages/purchases/parameters_model/add_purchase_parameters.dart';

part 'add_purchase_state.dart';

class AddPurchaseCubit extends Cubit<AddPurchaseState> {
  AddPurchaseCubit() : super(AddPurchaseInitial());

  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _shippingChargesController =
      TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  TextEditingController get purchaseDateController => _purchaseDateController;

  TextEditingController get shippingChargesController =>
      _shippingChargesController;

  TextEditingController get discountController => _discountController;

  @override
  Future<void> close() async {
    super.close();
    _purchaseDateController.dispose();
    _shippingChargesController.dispose();
    _discountController.dispose();
  }

  final List<String> _invoiceStatuses = ['received', 'pending', 'ordered'];

  final List<String> _discountTypes = ['none', 'fixed', 'percentage'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  GlobalKey<FormState> get formKey => _formKey;

  String? _invoiceStatus, _discountType;

  List<DropdownMenuItem<String>> invoiceStatusItems(BuildContext context) {
    return _invoiceStatuses
        .map((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(AppLocalizations.of(context).translate(e)),
            ))
        .toList();
  }

  List<DropdownMenuItem<String>> discountTypeItems(BuildContext context) {
    return _discountTypes
        .map((e) => DropdownMenuItem<String>(
              value: e,
              child: Text(AppLocalizations.of(context).translate(e)),
            ))
        .toList();
  }

  void selectInvoiceStatus(String? value) {
    _invoiceStatus = value;
  }

  void selectDiscountType(String? value) {
    _discountType = value;
  }

  List<DropdownMenuItem<int>> locationNameItems() {
    return _locationItems
        .map((e) => DropdownMenuItem<int>(
              value: e.id,
              child: Text(e.name),
            ))
        .toList();
  }

  final List<({int id, String name})> _locationItems = [];

  final List<({int id, String name})> _suppliersList = [];

  Future<void> _getLocationItem() async {
    List response = await System().get('location');
    for (var item in response) {
      _locationItems
          .add((id: int.parse(item['id'].toString()), name: item['name']));
    }
  }

  List<DropdownMenuItem<int>> supplierNameItems() {
    return _suppliersList
        .map((e) => DropdownMenuItem<int>(
              value: e.id,
              child: Text(e.name),
            ))
        .toList();
  }

  Future<void> _getSuppliers() async {
    final dio = Dio();
    var token = await System().getToken();
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["Authorization"] = "Bearer $token";
    final response = await dio.get(
        "${Api().baseUrl}${Api().apiUrl}/contactapi?type=supplier&per_page=50");
    List suppliers = response.data['data'];
    for (var element in suppliers) {
      _suppliersList.add((
        id: int.parse(element['id'].toString()),
        name: element['supplier_business_name'] ?? element['contact_id']
      ));
    }
  }

  int? _locationId;
  int? _supplierId;

  void selectLocation(int? value) {
    _locationId = value;
  }

  void selectSupplier(int? value) {
    _supplierId = value;
  }

  Future<void> getData() async {
    emit(GetDataLoading());
    try {
      await _getSuppliers();
      await _getLocationItem();
      emit(GetDataSuccessful());
    } catch (e) {
      emit(GetDataFailed());
    }
  }

  void onDateTimeChanged(DateTime dateTime) {
    _purchaseDateController.text = dateTime.toString();
  }

  void navigateToProductsSelection(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      PurchasesParameters purchasesParameters = PurchasesParameters(
          supplierId: _supplierId.toString(),
          locationId: _locationId!,
          purchaseDate: _purchaseDateController.text.isEmpty
              ? DateTime.now().toString()
              : _purchaseDateController.text,
          purchaseState: _invoiceStatus!,
          discountType: _discountType,
          discountAmount: _discountController.text);
      Navigator.pushNamed(context, '/products_selection',
          arguments: purchasesParameters);
    }
  }
}
