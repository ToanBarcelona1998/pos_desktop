import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/product_entity.dart';
import '../../repository/product_repository.dart';

/// Parameters for search products use case
class SearchProductsParams {
  final int locationId;
  final String query;
  final int? categoryId;
  final int? brandId;

  const SearchProductsParams({
    required this.locationId,
    required this.query,
    this.categoryId,
    this.brandId,
  });
}

/// Use case for searching products
class SearchProductsUseCase implements UseCase<List<ProductEntity>, SearchProductsParams> {
  final ProductRepository _repository;

  const SearchProductsUseCase(this._repository);

  @override
  Future<Result<List<ProductEntity>>> call(SearchProductsParams params) async {
    return await _repository.searchProducts(
      locationId: params.locationId,
      query: params.query,
      categoryId: params.categoryId,
      brandId: params.brandId,
    );
  }
}
