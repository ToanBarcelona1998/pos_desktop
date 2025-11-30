import '../../core/api_client.dart';

/// Remote data source for shipment operations
abstract class ShipmentRemoteDataSource {
  /// Get sells by shipment status
  Future<List<Map<String, dynamic>>> getSellsByShipmentStatus(String status, String date);

  /// Update shipment status
  Future<Map<String, dynamic>> updateShipmentStatus(Map<String, dynamic> data);
}

/// Implementation of [ShipmentRemoteDataSource]
class ShipmentRemoteDataSourceImpl implements ShipmentRemoteDataSource {
  final ApiClient _apiClient;
  final String _sellEndpoint;
  final String _updateStatusEndpoint;

  const ShipmentRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String sellEndpoint,
    required String updateStatusEndpoint,
  })  : _apiClient = apiClient,
        _sellEndpoint = sellEndpoint,
        _updateStatusEndpoint = updateStatusEndpoint;

  @override
  Future<List<Map<String, dynamic>>> getSellsByShipmentStatus(String status, String date) async {
    final response = await _apiClient.get(
      _sellEndpoint,
      queryParams: {
        'start_date': date,
        'shipping_status': status,
      },
    );
    final data = response['data'] as List<dynamic>?;
    return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }

  @override
  Future<Map<String, dynamic>> updateShipmentStatus(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_updateStatusEndpoint, body: data);
    return response;
  }
}




