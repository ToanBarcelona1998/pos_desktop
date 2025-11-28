part of 'purchase_checkout_cubit.dart';

abstract class PurchaseCheckoutState {}

class PurchaseCheckoutInitial extends PurchaseCheckoutState {}

class PurchaseCheckoutChangePayment extends PurchaseCheckoutState {}

class CheckOutSuccessState extends PurchaseCheckoutState {}

class CheckOutFailedState extends PurchaseCheckoutState {}

class CheckOutLoadingState extends PurchaseCheckoutState {}
