import '../../core/api_client.dart';
import '../../model/brand_model.dart';

/// Remote data source for brands
abstract class BrandRemoteDataSource {
  /// Gets all brands
  Future<List<BrandModel>> getBrands();

  /// Gets a brand by ID
  Future<BrandModel> getBrandById(int id);

  /// Creates a new brand
  Future<BrandModel> createBrand(Map<String, dynamic> data);

  /// Updates an existing brand
  Future<BrandModel> updateBrand(int id, Map<String, dynamic> data);

  /// Deletes a brand
  Future<void> deleteBrand(int id);
}

/// Implementation of [BrandRemoteDataSource]
class BrandRemoteDataSourceImpl implements BrandRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const BrandRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<BrandModel>> getBrands() async {
    final response = await _apiClient.get(_endpoint);
    final data = response['data'] as List<dynamic>;
    return data
        .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BrandModel> getBrandById(int id) async {
    final response = await _apiClient.get('$_endpoint/$id');
    return BrandModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<BrandModel> createBrand(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_endpoint, body: data);
    return BrandModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<BrandModel> updateBrand(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('$_endpoint/$id', body: data);
    return BrandModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<void> deleteBrand(int id) async {
    await _apiClient.delete('$_endpoint/$id');
  }
}





