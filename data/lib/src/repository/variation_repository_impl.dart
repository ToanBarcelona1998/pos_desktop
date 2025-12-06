import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/remote/variation_remote_data_source.dart';
import '../model/variation_model.dart';

/// Implementation of [VariationRepository]
class VariationRepositoryImpl implements VariationRepository {
  final VariationRemoteDataSource _remoteDataSource;

  const VariationRepositoryImpl({
    required VariationRemoteDataSource remoteDataSource,
  })  : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<VariationListResult>> getVariations(String url) async {
    try {
      final response = await _remoteDataSource.getVariations(url);
      final entities = response.variations.map(_mapToEntity).toList();
      return Success(VariationListResult(
        variations: entities,
        nextLink: response.nextLink,
      ));
    } catch (e) {
      Logger.logE('Error getting variations', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<VariationEntity>>> getVariationsForProduct(int productId) async {
    try {
      // This would need a specific endpoint - implement when available
      return const Success([]);
    } catch (e) {
      Logger.logE('Error getting variations for product', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> syncVariations(int locationId) async {
    try {
      // Implement sync logic when database is set up
      return const Success(null);
    } catch (e) {
      Logger.logE('Error syncing variations', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<VariationEntity>>> getLocalVariations() async {
    try {
      // Implement local storage retrieval when database is set up
      return const Success([]);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  VariationEntity _mapToEntity(VariationModel model) {
    return VariationEntity(
      id: model.id,
      productId: model.productId,
      name: model.name,
      subSku: model.subSku,
      defaultPurchasePrice: model.defaultPurchasePrice,
      dppIncTax: model.dppIncTax,
      profitPercent: model.profitPercent,
      defaultSellPrice: model.defaultSellPrice,
      sellPriceIncTax: model.sellPriceIncTax,
      variationValueId: model.variationValueId,
      createdAt: model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      updatedAt: model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null,
    );
  }
}












