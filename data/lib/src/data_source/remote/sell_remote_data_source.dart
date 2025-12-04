import '../../core/api_client.dart';
import '../../model/sell_model.dart';

/// Remote data source for sell operations
abstract class SellRemoteDataSource {
  /// Create a sell
  Future<SellModel> createSell(Map<String, dynamic> data);

  /// Update a sell
  Future<SellModel> updateSell(int id, Map<String, dynamic> data);

  /// Delete a sell
  Future<void> deleteSell(int id);

  /// Get sells
  Future<List<SellModel>> getSells({Map<String, dynamic>? query});

  /// Get specified sells by IDs
  Future<List<SellModel>> getSpecifiedSells(List<int> ids);
}

/// Implementation of [SellRemoteDataSource]
class SellRemoteDataSourceImpl implements SellRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const SellRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<SellModel> createSell(Map<String, dynamic> data) async {
    // Remove shipping fields from data before sending
    final cleanedData = _removeShippingFields(data);
    final response = await _apiClient.post(_endpoint, body: cleanedData);
    final sellData = response['data'];
    if (sellData is List && sellData.isNotEmpty) {
      return SellModel.fromJson(sellData.first as Map<String, dynamic>);
    }
    return SellModel.fromJson(sellData ?? response);
  }

  @override
  Future<SellModel> updateSell(int id, Map<String, dynamic> data) async {
    final cleanedData = _removeShippingFields(data);
    final response = await _apiClient.put('$_endpoint/$id', body: cleanedData);
    return SellModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<void> deleteSell(int id) async {
    await _apiClient.delete('$_endpoint/$id');
  }

  @override
  Future<List<SellModel>> getSells({Map<String, dynamic>? query}) async {
    final response = await _apiClient.get(_endpoint, queryParams: query);
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => SellModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SellModel>> getSpecifiedSells(List<int> ids) async {
    final idsString = ids.join(',');
    final response = await _apiClient.get('$_endpoint/$idsString');
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => SellModel.fromJson(_removeShippingFields(json as Map<String, dynamic>)))
        .toList();
  }

  Map<String, dynamic> _removeShippingFields(Map<String, dynamic> data) {
    final cleaned = Map<String, dynamic>.from(data);
    cleaned['shipping_charges'] = 0.0;
    cleaned['shipping_details'] = null;
    cleaned['shipping_address'] = null;
    cleaned['shipping_status'] = null;
    cleaned['delivered_to'] = null;
    return cleaned;
  }
}









