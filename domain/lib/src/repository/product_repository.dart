import '../core/result.dart';
import '../entity/product_entity.dart';

/// Abstract repository for product operations.
abstract class ProductRepository {
  /// Gets products by location
  Future<Result<List<ProductEntity>>> getProducts({
    required int locationId,
    int page = 1,
    int perPage = 10,
    String? searchQuery,
  });

  /// Gets a product by ID
  Future<Result<ProductEntity>> getProductById(int id);

  /// Searches products
  Future<Result<List<ProductEntity>>> searchProducts({
    required int locationId,
    required String query,
    int? categoryId,
    int? brandId,
  });

  /// Syncs products from remote to local
  Future<Result<void>> syncProducts(int locationId);

  /// Gets cached products
  Future<Result<List<ProductEntity>>> getCachedProducts({
    required int locationId,
    int offset = 0,
    int limit = 10,
    String? searchTerm,
  });

  /// Clears product cache
  Future<Result<void>> clearCache();

  /// Checks if products need update
  Future<Result<bool>> needsUpdate();
}








