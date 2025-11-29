import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/sell_entity.dart';
import '../../repository/sell_repository.dart';

/// Use case for creating a sell
class CreateSellUseCase implements UseCase<SellEntity, SellEntity> {
  final SellRepository _repository;

  const CreateSellUseCase(this._repository);

  @override
  Future<Result<SellEntity>> call(SellEntity sell) async {
    return await _repository.createSell(sell);
  }
}
