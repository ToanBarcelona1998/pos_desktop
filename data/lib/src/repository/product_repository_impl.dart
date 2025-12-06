import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/local/product_local_data_source.dart';
import '../data_source/remote/product_remote_data_source.dart';
import '../model/product_model.dart';

/// Implementation of [ProductRepository]
/// Prioritizes local data for offline-first approach
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;

  const ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    required ProductLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Result<List<ProductEntity>>> getProducts({
    required int locationId,
    int page = 1,
    int perPage = 10,
    String? searchQuery,
  }) async {
    // Always try local first (offline-first)
    try {
      final cachedProducts = await _localDataSource.getProducts(
        locationId: locationId,
        offset: (page - 1) * perPage,
        limit: perPage,
        searchTerm: searchQuery,
      );

      if (cachedProducts.isNotEmpty) {
        // Return local data immediately
        final entities = cachedProducts.map(_mapToEntity).toList();
        
        // Sync in background for next time
        _syncProductsInBackground(locationId);
        
        return Success(entities);
      }
    } catch (e) {
      Logger.logE('Error getting cached products', e);
    }

    // If no local data, fetch from remote
    try {
      final response = await _remoteDataSource.getProducts(
        locationId: locationId,
        page: page,
        perPage: perPage,
      );
      final entities = response.products.map(_mapToEntity).toList();
      
      // Save to local for offline use
      await _localDataSource.saveProducts(
        response.products,
        locationId,
        productsJson: response.rawProductsJson,
      );
      
      return Success(entities);
    } catch (e) {
      Logger.logE('Failed to fetch products from server', e);
      // Offline and no local data
      return const Success([]);
    }
  }

  @override
  Future<Result<ProductEntity>> getProductById(int id) async {
    // Try local first
    try {
      final products = await _localDataSource.getProducts(
        locationId: 0, // Get all
        limit: 1000,
      );
      final product = products.firstWhere(
        (p) => p.id == id || p.variationId == id,
        orElse: () => throw Exception('Not found'),
      );
      return Success(_mapToEntity(product));
    } catch (_) {
      // Try remote
      try {
        final product = await _remoteDataSource.getProductById(id);
        return Success(_mapToEntity(product));
      } catch (e) {
        Logger.logE('Failed to get product from server', e);
        return const Error(NotFoundFailure(message: 'Product not found'));
      }
    }
  }

  @override
  Future<Result<List<ProductEntity>>> searchProducts({
    required int locationId,
    required String query,
    int? categoryId,
    int? brandId,
  }) async {
    // Always try local first
    try {
      final products = await _localDataSource.getProducts(
        locationId: locationId,
        searchTerm: query,
        limit: 100,
      );

      var filtered = products.map(_mapToEntity);

      if (categoryId != null) {
        filtered = filtered.where((p) => p.categoryId == categoryId);
      }
      if (brandId != null) {
        filtered = filtered.where((p) => p.brandId == brandId);
      }

      final result = filtered.toList();
      if (result.isNotEmpty) {
        return Success(result);
      }
    } catch (e) {
      Logger.logE('Error searching local products', e);
    }

    // If no local results, try remote
    try {
      return await getProducts(locationId: locationId, perPage: 100, searchQuery: query);
    } catch (e) {
      Logger.logE('Failed to search products from server', e);
      return const Success([]);
    }
  }

  /// Sync products in background without blocking
  void _syncProductsInBackground(int locationId) {
    syncProducts(locationId).catchError((e) {
      Logger.logE('Background product sync error', e);
    });
  }

  @override
  Future<Result<void>> syncProducts(int locationId) async {
    try {
      int page = 1;
      bool hasMore = true;
      final List<ProductModel> allProducts = [];

      final List<Map<String, dynamic>> allRawProductsJson = [];
      
      while (hasMore) {
        final response = await _remoteDataSource.getProducts(
          locationId: locationId,
          page: page,
          perPage: 100,
        );

        allProducts.addAll(response.products);
        if (response.rawProductsJson != null) {
          allRawProductsJson.addAll(response.rawProductsJson!);
        }
        hasMore = response.hasMore;
        page++;
      }

      await _localDataSource.saveProducts(
        allProducts,
        locationId,
        productsJson: allRawProductsJson.isNotEmpty ? allRawProductsJson : null,
      );
      await _localDataSource.updateLastSync();

      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getCachedProducts({
    required int locationId,
    int offset = 0,
    int limit = 10,
    String? searchTerm,
  }) async {
    try {
      final products = await _localDataSource.getProducts(
        locationId: locationId,
        offset: offset,
        limit: limit,
        searchTerm: searchTerm,
      );
      final entities = products.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> clearCache() async {
    try {
      await _localDataSource.clearCache();
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<bool>> needsUpdate() async {
    try {
      final needsUpdate = await _localDataSource.needsUpdate();
      return Success(needsUpdate);
    } catch (e) {
      return const Success(true);
    }
  }

  ProductEntity _mapToEntity(ProductModel model) {
    // Use variation_id as id if id is null (like old code)
    final id = model.id ?? model.variationId ?? 0;
    
    return ProductEntity(
      id: id,
      productId: model.productId,
      variationId: model.variationId,
      productName: model.productName,
      productVariationName: model.productVariationName,
      variationName: model.variationName,
      displayName: model.displayName ?? '', // Ensure displayName is never null
      sku: model.sku,
      subSku: model.subSku,
      type: model.type,
      enableStock: model.enableStock == 1,
      brandId: model.brandId,
      unitId: model.unitId,
      categoryId: model.categoryId,
      subCategoryId: model.subCategoryId,
      taxId: model.taxId,
      defaultSellPrice: model.defaultSellPrice,
      sellPriceIncTax: model.sellPriceIncTax,
      productImageUrl: model.productImageUrl,
      productDescription: model.productDescription,
      qtyAvailable: model.qtyAvailable,
    );
  }
}
