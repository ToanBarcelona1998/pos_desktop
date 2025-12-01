import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../repository/brand_repository.dart';

/// Use case for deleting a brand
class DeleteBrandUseCase implements UseCase<void, int> {
  final BrandRepository _brandRepository;

  const DeleteBrandUseCase(this._brandRepository);

  @override
  Future<Result<void>> call(int brandId) async {
    return await _brandRepository.deleteBrand(brandId);
  }
}






