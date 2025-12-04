import '../../core/api_client.dart';
import '../../model/purchase_model.dart';

/// Remote data source for purchase operations
abstract class PurchaseRemoteDataSource {
  /// Get all purchases
  Future<List<PurchaseModel>> getPurchases({Map<String, dynamic>? query});

  /// Get purchase by ID
  Future<PurchaseModel> getPurchaseById(int id);

  /// Create a new purchase
  Future<PurchaseModel> createPurchase(Map<String, dynamic> data);

  /// Update a purchase
  Future<PurchaseModel> updatePurchase(int id, Map<String, dynamic> data);

  /// Delete a purchase
  Future<void> deletePurchase(int id);
}

/// Implementation of [PurchaseRemoteDataSource]
class PurchaseRemoteDataSourceImpl implements PurchaseRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const PurchaseRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<PurchaseModel>> getPurchases({Map<String, dynamic>? query}) async {
    final response = await _apiClient.get(_endpoint, queryParams: query);
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => PurchaseModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PurchaseModel> getPurchaseById(int id) async {
    final response = await _apiClient.get('$_endpoint/$id');
    return PurchaseModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<PurchaseModel> createPurchase(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_endpoint, body: data);
    return PurchaseModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<PurchaseModel> updatePurchase(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('$_endpoint/$id', body: data);
    return PurchaseModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<void> deletePurchase(int id) async {
    await _apiClient.delete('$_endpoint/$id');
  }
}










