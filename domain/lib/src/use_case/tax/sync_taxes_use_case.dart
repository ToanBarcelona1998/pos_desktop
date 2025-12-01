import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../repository/tax_repository.dart';

/// Use case for syncing taxes
class SyncTaxesUseCase implements UseCaseNoParams<void> {
  final TaxRepository _repository;

  const SyncTaxesUseCase(this._repository);

  @override
  Future<Result<void>> call() async {
    return await _repository.syncTaxes();
  }
}






