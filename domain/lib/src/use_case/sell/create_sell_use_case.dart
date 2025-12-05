import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/sell_entity.dart';
import '../../repository/sell_repository.dart';

/// Use case for creating a sell
/// Handles business logic: try server first, then save locally with sync status
class CreateSellUseCase implements UseCase<SellEntity, SellEntity> {
  final SellRepository _repository;

  CreateSellUseCase(
    this._repository,
  );

  @override
  Future<Result<SellEntity>> call(SellEntity sell) async {
    try {
      final serverResult = await _repository.createSellOnServer(sell);

      return await serverResult.fold(
        onSuccess: (syncedSell) async {
          // Server submission successful - save locally with sync status
          return await _repository.saveSellLocallyWithSyncData(sell, syncedSell);
        },
        onError: (_) async {
          // Server submission failed - save locally as unsynced
          return await _repository.saveSellLocally(sell);
        },
      );
    } catch (e) {
      // Exception occurred during server call - save locally as unsynced
      // Error is visible (not hidden) - will be logged by bloc
      return await _repository.saveSellLocally(sell);
    }
  }
}
