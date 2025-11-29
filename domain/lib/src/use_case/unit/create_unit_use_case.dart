import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/unit_entity.dart';
import '../../repository/unit_repository.dart';

/// Parameters for create unit use case
class CreateUnitParams {
  final String actualName;
  final String shortName;
  final bool allowDecimal;

  const CreateUnitParams({
    required this.actualName,
    required this.shortName,
    this.allowDecimal = false,
  });
}

/// Use case for creating a unit
class CreateUnitUseCase implements UseCase<UnitEntity, CreateUnitParams> {
  final UnitRepository _repository;

  const CreateUnitUseCase(this._repository);

  @override
  Future<Result<UnitEntity>> call(CreateUnitParams params) async {
    return await _repository.createUnit(
      actualName: params.actualName,
      shortName: params.shortName,
      allowDecimal: params.allowDecimal,
    );
  }
}

