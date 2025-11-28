part of 'add_purchase_cubit.dart';

abstract class AddPurchaseState {}

class AddPurchaseInitial extends AddPurchaseState {}

class GetDataLoading extends AddPurchaseState {}

class GetDataSuccessful extends AddPurchaseState {}

class GetDataFailed extends AddPurchaseState {}
