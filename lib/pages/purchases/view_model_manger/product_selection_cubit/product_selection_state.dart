part of 'product_selection_cubit.dart';


abstract class ProductSelectionState {}

class ProductSelectionInitial extends ProductSelectionState {}

class ProductsGetDataLoadingState extends ProductSelectionState {}

class ProductsGetDataFailedState extends ProductSelectionState {}

class ProductsIncreaseQuantityState extends ProductSelectionState {}

class ProductsDecreaseQuantityState extends ProductSelectionState {}

class ProductsGetDataSuccessState extends ProductSelectionState {}
