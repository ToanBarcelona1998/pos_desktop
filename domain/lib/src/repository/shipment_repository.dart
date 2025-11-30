import '../core/result.dart';
import '../entity/shipment_entity.dart';

/// Repository interface for shipment operations
abstract class ShipmentRepository {
  /// Get sells by shipment status
  Future<Result<List<ShipmentEntity>>> getSellsByShipmentStatus({
    required ShipmentStatus status,
    required DateTime date,
  });

  /// Update shipment status
  Future<Result<ShipmentEntity>> updateShipmentStatus({
    required int sellId,
    required ShipmentStatus status,
    String? deliveredTo,
    String? shippingDetails,
  });
}





