import '../core/entity.dart';

/// Shipment status enum
enum ShipmentStatus {
  ordered,
  packed,
  shipped,
  delivered,
  cancelled;

  static ShipmentStatus fromString(String value) {
    return ShipmentStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => ShipmentStatus.ordered,
    );
  }
}

/// Shipment entity representing shipping information
class ShipmentEntity extends Entity {
  final int sellId;
  final ShipmentStatus status;
  final String? shippingDetails;
  final String? shippingAddress;
  final String? deliveredTo;
  final double? shippingCharges;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const ShipmentEntity({
    required this.sellId,
    required this.status,
    this.shippingDetails,
    this.shippingAddress,
    this.deliveredTo,
    this.shippingCharges,
    this.shippedAt,
    this.deliveredAt,
  });

  @override
  List<Object?> get props => [
        sellId,
        status,
        shippingDetails,
        shippingAddress,
        deliveredTo,
        shippingCharges,
        shippedAt,
        deliveredAt,
      ];
}












