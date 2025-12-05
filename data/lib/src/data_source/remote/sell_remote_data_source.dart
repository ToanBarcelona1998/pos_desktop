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

    // API response structure: {'data': [sellObject]} or {'data': sellObject}
    final responseData = response['data'];

    // Handle List response (most common case)
    if (responseData is List) {
      if (responseData.isNotEmpty) {
        final firstItem = responseData.first;
        // Ensure firstItem is a Map
        if (firstItem is Map<String, dynamic>) {
          return SellModel.fromJson(firstItem);
        } else if (firstItem is Map) {
          // Convert dynamic Map to Map<String, dynamic>
          return SellModel.fromJson(Map<String, dynamic>.from(firstItem));
        } else {
          throw Exception(
              'Invalid response format: expected Map, got ${firstItem.runtimeType}');
        }
      } else {
        throw Exception('Empty response data list');
      }
    }

    // Handle Map response
    if (responseData is Map<String, dynamic>) {
      return SellModel.fromJson(responseData);
    } else if (responseData is Map) {
      return SellModel.fromJson(Map<String, dynamic>.from(responseData));
    }
    // If response['data'] is null, try using response directly
    return SellModel.fromJson(response);
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
        .map((json) => SellModel.fromJson(
            _removeShippingFields(json as Map<String, dynamic>)))
        .toList();
  }

  Map<String, dynamic> _removeShippingFields(Map<String, dynamic> data) {
    final cleaned = Map<String, dynamic>.from(data);

    // Handle case where data contains 'sells' array (like {'sells': [sellData]})
    if (cleaned.containsKey('sells') && cleaned['sells'] is List) {
      cleaned['sells'] = (cleaned['sells'] as List).map((sell) {
        if (sell is Map) {
          final sellMap = Map<String, dynamic>.from(sell);
          sellMap['shipping_charges'] = 0.0;
          sellMap['shipping_details'] = null;
          sellMap['shipping_address'] = null;
          sellMap['shipping_status'] = null;
          sellMap['delivered_to'] = null;
          return sellMap;
        }
        return sell;
      }).toList();
    } else {
      // Remove shipping fields from top level
      cleaned['shipping_charges'] = 0.0;
      cleaned['shipping_details'] = null;
      cleaned['shipping_address'] = null;
      cleaned['shipping_status'] = null;
      cleaned['delivered_to'] = null;
    }

    return cleaned;
  }
}
