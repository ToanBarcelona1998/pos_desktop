import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../repository/sell_repository.dart';

/// Use case for deleting a sell
/// Handles business logic: delete from server if online, then delete locally
class DeleteSellUseCase implements UseCase<void, int> {
  final SellRepository _repository;

  DeleteSellUseCase(
    this._repository,
  );

  @override
  Future<Result<void>> call(int sellId) async {
    try {
      // Try to delete from server (ignore result - always delete locally)
      await _repository.deleteSell(sellId);
    } catch (e) {
      // Server deletion failed - continue to delete locally
    }

    // Always delete locally (whether online or offline)
    return _repository.deleteSellLocally(sellId);
  }
}

