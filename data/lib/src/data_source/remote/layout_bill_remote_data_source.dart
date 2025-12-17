import '../../core/api_client.dart';

/// Remote data source for layout bill operations
abstract class LayoutBillRemoteDataSource {
  /// Get layout bill information
  Future<Map<String, dynamic>> getLayoutBill(int locationId);
}

/// Implementation of [LayoutBillRemoteDataSource]
class LayoutBillRemoteDataSourceImpl implements LayoutBillRemoteDataSource {
  final ApiClient _apiClient;
  final String _layoutBillEndpoint;

  const LayoutBillRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String layoutBillEndpoint,
  })  : _apiClient = apiClient,
        _layoutBillEndpoint = layoutBillEndpoint;

  @override
  Future<Map<String, dynamic>> getLayoutBill(int locationId) async {
    final response = await _apiClient.get(
      '$_layoutBillEndpoint?location_id=$locationId',
    );
    return response['data'] as Map<String, dynamic>;
  }
}

