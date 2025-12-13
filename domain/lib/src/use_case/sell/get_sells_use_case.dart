import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/sell_entity.dart';
import '../../repository/sell_repository.dart';

/// Use case for getting local sells
class GetLocalSellsUseCase implements UseCaseNoParams<List<SellEntity>> {
  final SellRepository _repository;

  const GetLocalSellsUseCase(this._repository);

  @override
  Future<Result<List<SellEntity>>> call() async {
    return await _repository.getLocalSells();
  }
}

/// Use case for getting sells by IDs
class GetSellsByIdsUseCase implements UseCase<List<SellEntity>, List<int>> {
  final SellRepository _repository;

  const GetSellsByIdsUseCase(this._repository);

  @override
  Future<Result<List<SellEntity>>> call(List<int> ids) async {
    return await _repository.getSellsByIds(ids);
  }
}

/// Use case for getting final sells
class GetFinalSellsUseCase implements UseCaseNoParams<List<SellEntity>> {
  final SellRepository _repository;

  const GetFinalSellsUseCase(this._repository);

  @override
  Future<Result<List<SellEntity>>> call() async {
    return await _repository.getFinalSells();
  }
}
