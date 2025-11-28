import 'package:equatable/equatable.dart';
import 'package:pos_final/models/product_item_model.dart';

class PurchasesParameters extends Equatable {
  final String supplierId;
  final int locationId;
  final String purchaseDate;
  final String purchaseState;
  final Map<Data, int>? products;
  final String? discountType;
  final String? discountAmount;
  final String? shippingCharge;

//Payment
  const PurchasesParameters(
      {required this.supplierId,
      required this.locationId,
      required this.purchaseDate,
      required this.purchaseState,
      this.products,
      this.discountType,
      this.discountAmount,
      this.shippingCharge});

  PurchasesParameters copyWith({
    String? supplierId,
    int? locationId,
    String? purchaseDate,
    String? purchaseState,
    Map<Data, int>? products,
    String? discountType,
    String? discountAmount,
    String? shippingCharge,
  }) {
    return PurchasesParameters(
        supplierId: supplierId ?? this.supplierId,
        locationId: locationId ?? this.locationId,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        purchaseState: purchaseState ?? this.purchaseState,
        products: products,
        discountType: discountType,
        discountAmount: discountAmount,
        shippingCharge: shippingCharge);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'supplierId': supplierId,
      'locationId': locationId,
      'purchaseDate': purchaseDate,
      'purchaseState': purchaseState,
      'products': products,
      'discountType': discountType,
      'discountAmount': discountAmount,
      'shippingCharge': shippingCharge,
    };

    return data;
  }

  @override
  List<Object?> get props => [
        supplierId,
        locationId,
        purchaseDate,
        purchaseState,
        products,
        discountType,
        discountAmount,
        shippingCharge,
      ];
// final PaymentData? payment;
}
