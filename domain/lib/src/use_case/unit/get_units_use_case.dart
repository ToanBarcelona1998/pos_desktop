import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/unit_entity.dart';
import '../../repository/unit_repository.dart';

/// Use case for getting all units
class GetUnitsUseCase implements UseCaseNoParams<List<UnitEntity>> {
  final UnitRepository _repository;

  const GetUnitsUseCase(this._repository);

  @override
  Future<Result<List<UnitEntity>>> call() async {
    return await _repository.getUnits();
  }
}








