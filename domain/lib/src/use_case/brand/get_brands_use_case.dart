import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/brand_entity.dart';
import '../../repository/brand_repository.dart';

/// Use case for getting all brands
class GetBrandsUseCase implements UseCaseNoParams<List<BrandEntity>> {
  final BrandRepository _brandRepository;

  const GetBrandsUseCase(this._brandRepository);

  @override
  Future<Result<List<BrandEntity>>> call() async {
    return await _brandRepository.getBrands();
  }
}

