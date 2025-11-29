import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/product_local_data_source.dart';
import '../data_source/remote/product_remote_data_source.dart';
import '../model/product_model.dart';

/// Implementation of [ProductRepository]
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;
  final ProductLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  const ProductRepositoryImpl({
    required ProductRemoteDataSource remoteDataSource,
    required ProductLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<ProductEntity>>> getProducts({
    required int locationId,
    int page = 1,
    int perPage = 10,
    String? searchQuery,
  }) async {
    if (!await _networkInfo.isConnected) {
      return getCachedProducts(locationId: locationId);
    }

    try {
      final response = await _remoteDataSource.getProducts(
        locationId: locationId,
        page: page,
        perPage: perPage,
      );
      final entities = response.products.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<ProductEntity>> getProductById(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final product = await _remoteDataSource.getProductById(id);
      return Success(_mapToEntity(product));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ProductEntity>>> searchProducts({
    required int locationId,
    required String query,
    int? categoryId,
    int? brandId,
  }) async {
    // Try cached products first with search term
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

      return Success(filtered.toList());
    } catch (e) {
      // Fallback to remote search
      if (await _networkInfo.isConnected) {
        return getProducts(locationId: locationId, perPage: 100, searchQuery: query);
      }
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> syncProducts(int locationId) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      int page = 1;
      bool hasMore = true;
      final List<ProductModel> allProducts = [];

      while (hasMore) {
        final response = await _remoteDataSource.getProducts(
          locationId: locationId,
          page: page,
          perPage: 100,
        );

        allProducts.addAll(response.products);
        hasMore = response.hasMore;
        page++;
      }

      await _localDataSource.saveProducts(allProducts, locationId);
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
    return ProductEntity(
      id: model.id ?? 0,
      productId: model.productId,
      variationId: model.variationId,
      productName: model.productName,
      productVariationName: model.productVariationName,
      variationName: model.variationName,
      displayName: model.displayName,
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
