import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/brand_entity.dart';
import '../../repository/brand_repository.dart';

class CreateBrandParams {
  final String name;
  final String? description;
  final bool? useForRepair;

  const CreateBrandParams({
    required this.name,
    this.description,
    this.useForRepair,
  });
}

/// Use case for creating a new brand
class CreateBrandUseCase implements UseCase<BrandEntity, CreateBrandParams> {
  final BrandRepository _brandRepository;

  const CreateBrandUseCase(this._brandRepository);

  @override
  Future<Result<BrandEntity>> call(CreateBrandParams params) async {
    return await _brandRepository.createBrand(
      name: params.name,
      description: params.description,
      useForRepair: params.useForRepair,
    );
  }
}














