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
/// Uses /variation endpoint to match old API structure
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

    // Use variation endpoint like old code: /variation?per_page=3000&not_for_selling=0
    final response = await _apiClient.get(
      _endpoint,
      queryParams: {
        'location_id': locationId,
        'per_page': perPage,
        'page': page,
        'not_for_selling': 0,
      },
      headers: headers,
    );

    // Handle response structure: { data: [...], links: {...}, meta: {...} }
    final data = response['data'] as List<dynamic>? ?? [];
    final products = data
        .map((json) {
          // Construct display_name if not present (like old code)
          final jsonMap = json as Map<String, dynamic>;
          if (jsonMap['display_name'] == null || jsonMap['display_name'].toString().isEmpty) {
            final productName = jsonMap['product_name']?.toString() ?? '';
            final productVariationName = jsonMap['product_variation_name']?.toString() ?? '';
            final variationName = jsonMap['variation_name']?.toString() ?? '';
            jsonMap['display_name'] = '$productName $productVariationName $variationName'.trim();
          }
          return ProductModel.fromJson(jsonMap);
        })
        .toList();

    final meta = response['meta'] as Map<String, dynamic>?;
    final total = meta?['total'] as int? ?? products.length;
    final lastPage = meta?['last_page'] as int? ?? 1;
    final currentPage = meta?['current_page'] as int? ?? page;

    return ProductListResponse(
      products: products,
      total: total,
      currentPage: currentPage,
      lastPage: lastPage,
    );
  }

  @override
  Future<ProductModel> getProductById(int id) async {
    final response = await _apiClient.get('$_endpoint/$id');
    final json = response['data'] ?? response;
    final jsonMap = json as Map<String, dynamic>;
    
    // Construct display_name if not present
    if (jsonMap['display_name'] == null || jsonMap['display_name'].toString().isEmpty) {
      final productName = jsonMap['product_name']?.toString() ?? '';
      final productVariationName = jsonMap['product_variation_name']?.toString() ?? '';
      final variationName = jsonMap['variation_name']?.toString() ?? '';
      jsonMap['display_name'] = '$productName $productVariationName $variationName'.trim();
    }
    
    return ProductModel.fromJson(jsonMap);
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
