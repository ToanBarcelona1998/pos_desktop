import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/product_entity.dart';
import '../../repository/product_repository.dart';

/// Parameters for get products use case
class GetProductsParams {
  final int locationId;
  final int page;
  final int perPage;
  final String? searchQuery;

  const GetProductsParams({
    required this.locationId,
    this.page = 1,
    this.perPage = 10,
    this.searchQuery,
  });
}

/// Use case for getting products
class GetProductsUseCase implements UseCase<List<ProductEntity>, GetProductsParams> {
  final ProductRepository _repository;

  const GetProductsUseCase(this._repository);

  @override
  Future<Result<List<ProductEntity>>> call(GetProductsParams params) async {
    return await _repository.getProducts(
      locationId: params.locationId,
      page: params.page,
      perPage: params.perPage,
      searchQuery: params.searchQuery,
    );
  }
}
