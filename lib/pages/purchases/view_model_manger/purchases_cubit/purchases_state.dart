part of 'purchases_cubit.dart';

abstract class PurchasesState {}

class PurchasesInitial extends PurchasesState {}

class PurchasesGetDataLoading extends PurchasesState {
  PurchasesGetDataLoading();
}

class PurchasesGetDataSuccessful extends PurchasesState {
   final List<Purchase> purchases;
  PurchasesGetDataSuccessful(this.purchases);
}

class PurchasesGetDataFailed extends PurchasesState {
  PurchasesGetDataFailed();
}
