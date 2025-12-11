import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/product_entity.dart';
import '../../repository/product_repository.dart';

/// Parameters for find product by SKU use case
class FindProductBySkuParams {
  final int locationId;
  final String sku;

  const FindProductBySkuParams({
    required this.locationId,
    required this.sku,
  });
}

/// Use case for finding a product by SKU (exact match)
class FindProductBySkuUseCase implements UseCase<ProductEntity?, FindProductBySkuParams> {
  final ProductRepository _repository;

  const FindProductBySkuUseCase(this._repository);

  @override
  Future<Result<ProductEntity?>> call(FindProductBySkuParams params) async {
    return await _repository.findProductBySku(
      locationId: params.locationId,
      sku: params.sku,
    );
  }
}

