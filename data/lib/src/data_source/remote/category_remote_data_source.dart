import '../../core/api_client.dart';
import '../../model/category_model.dart';

/// Remote data source for category operations
abstract class CategoryRemoteDataSource {
  /// Get all categories
  Future<List<CategoryModel>> getCategories();
}

/// Implementation of [CategoryRemoteDataSource]
class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const CategoryRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _apiClient.get(_endpoint, queryParams: {'type': 'product'});
    final data = response['data'] as List<dynamic>;
    return data
        .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

