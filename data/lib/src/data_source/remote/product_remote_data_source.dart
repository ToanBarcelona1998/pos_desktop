import '../../core/api_client.dart';
import '../../model/product_model.dart';

/// Remote data source for product operations
abstract class ProductRemoteDataSource {
  /// Get products with pagination
  Future<ProductListResponse> getProducts({
    required int locationId,
    int page = 1,
    int perPage = 10,
    bool bypassCache = false,
  });

  /// Get product by ID
  Future<ProductModel> getProductById(int id);
}

/// Implementation of [ProductRemoteDataSource]
class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const ProductRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<ProductListResponse> getProducts({
    required int locationId,
    int page = 1,
    int perPage = 10,
    bool bypassCache = false,
  }) async {
    final headers = bypassCache
        ? {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
          }
        : null;

    final response = await _apiClient.get(
      _endpoint,
      queryParams: {
        'location_id': locationId,
        'page': page,
        'per_page': perPage,
      },
      headers: headers,
    );

    final data = response['data'] as List<dynamic>? ?? [];
    final products = data
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();

    final meta = response['meta'] as Map<String, dynamic>?;
    final total = meta?['total'] as int? ?? products.length;
    final lastPage = meta?['last_page'] as int? ?? 1;

    return ProductListResponse(
      products: products,
      total: total,
      currentPage: page,
      lastPage: lastPage,
    );
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    final response = await _apiClient.get('$_endpoint/$id');
    return ProductModel.fromJson(response['data'] ?? response);
  }
}

/// Response class for paginated product list
class ProductListResponse {
  final List<ProductModel> products;
  final int total;
  final int currentPage;
  final int lastPage;

  const ProductListResponse({
    required this.products,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

