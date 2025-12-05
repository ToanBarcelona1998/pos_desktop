import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/sell_entity.dart';
import '../../repository/sell_repository.dart';

/// Use case for getting suspended sells
class GetSuspendedSellsUseCase implements UseCaseNoParams<List<SellEntity>> {
  final SellRepository _repository;

  const GetSuspendedSellsUseCase(this._repository);

  @override
  Future<Result<List<SellEntity>>> call() async {
    return await _repository.getSuspendedSells();
  }
}

