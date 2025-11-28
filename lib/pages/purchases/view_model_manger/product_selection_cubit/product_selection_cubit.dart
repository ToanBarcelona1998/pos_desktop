import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/apis/products.dart';
import 'package:pos_final/helpers/api_handler/api_response.dart';
import 'package:pos_final/models/product_item_model.dart';
import 'package:pos_final/pages/purchases/parameters_model/add_purchase_parameters.dart';

part 'product_selection_state.dart';

class ProductSelectionCubit extends Cubit<ProductSelectionState> {
  ProductSelectionCubit() : super(ProductSelectionInitial());

  Map<Data, int> selectedProducts = {};

  late ProductItemModel productItem;

  final ScrollController scrollController = ScrollController();
  int _page = 1;
  bool canPaginate = false;

  @override
  Future<void> close() async {
    super.close();
    scrollController.dispose();
  }

  Future<void> getProducts(int locationId, bool isPaginate) async {
    if (!isPaginate) emit(ProductsGetDataLoadingState());
    ApiResponse apiResponse =
        await ProductsService().getProducts(locationId, page: _page);
    if (apiResponse.response?.statusCode == 200) {
      ProductItemModel temp =
          ProductItemModel.fromJson(apiResponse.response!.data);
      if (_page == 1) {
        productItem = temp;
      } else {
        productItem.data!.addAll(temp.data!);
      }
      if (temp.meta!.lastPage! - temp.meta!.currentPage! != 0) {
        canPaginate = true;
        _page++;
      } else {
        canPaginate = false;
      }
      emit(ProductsGetDataSuccessState());
    } else {
      emit(ProductsGetDataFailedState());
    }
  }

  void increaseProductQuantity(Data product) {
    if (selectedProducts.containsKey(product)) {
      selectedProducts[product] = selectedProducts[product]! + 1;
    } else {
      selectedProducts[product] = 1;
    }
    emit(ProductsIncreaseQuantityState());
  }

  void decreaseProductQuantity(Data product) {
    selectedProducts[product] = selectedProducts[product]! - 1;
    if (selectedProducts[product]! == 0) {
      selectedProducts.remove(product);
    }
    emit(ProductsDecreaseQuantityState());
  }

  int selectedProductQuantity(Data product) {
    if (selectedProducts.containsKey(product)) {
      return selectedProducts[product]!;
    }
    return 0;
  }

  void navigateToCheckOutScreen(
      BuildContext context, PurchasesParameters purchasesParameters) {
    PurchasesParameters newPurchasesParameters =
        purchasesParameters.copyWith(products: selectedProducts);
    Navigator.pushNamed(context, '/purchase_checkout',
        arguments: newPurchasesParameters);
  }
}
