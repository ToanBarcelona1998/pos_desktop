import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/shipment_remote_data_source.dart';

/// Implementation of [ShipmentRepository]
class ShipmentRepositoryImpl implements ShipmentRepository {
  final ShipmentRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ShipmentRepositoryImpl({
    required ShipmentRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<ShipmentEntity>>> getSellsByShipmentStatus({
    required ShipmentStatus status,
    required DateTime date,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final sells = await _remoteDataSource.getSellsByShipmentStatus(
        status.name,
        dateStr,
      );
      final entities = sells.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<ShipmentEntity>> updateShipmentStatus({
    required int sellId,
    required ShipmentStatus status,
    String? deliveredTo,
    String? shippingDetails,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'transaction_id': sellId,
        'shipping_status': status.name,
        if (deliveredTo != null) 'delivered_to': deliveredTo,
        if (shippingDetails != null) 'shipping_details': shippingDetails,
      };

      final response = await _remoteDataSource.updateShipmentStatus(data);
      return Success(_mapToEntity(response));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  ShipmentEntity _mapToEntity(Map<String, dynamic> json) {
    return ShipmentEntity(
      sellId: json['id'] as int? ?? json['transaction_id'] as int? ?? 0,
      status: ShipmentStatus.fromString(json['shipping_status']?.toString() ?? 'ordered'),
      shippingDetails: json['shipping_details'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      deliveredTo: json['delivered_to'] as String?,
      shippingCharges: (json['shipping_charges'] as num?)?.toDouble(),
      shippedAt: json['shipped_at'] != null
          ? DateTime.tryParse(json['shipped_at'].toString())
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString())
          : null,
    );
  }
}







