import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/tax_entity.dart';
import '../../repository/tax_repository.dart';

/// Use case for getting all taxes
class GetTaxesUseCase implements UseCaseNoParams<List<TaxEntity>> {
  final TaxRepository _repository;

  const GetTaxesUseCase(this._repository);

  @override
  Future<Result<List<TaxEntity>>> call() async {
    return await _repository.getTaxes();
  }
}











