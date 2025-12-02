import '../core/result.dart';
import '../entity/tax_entity.dart';

/// Repository interface for tax operations
abstract class TaxRepository {
  /// Get all taxes
  Future<Result<List<TaxEntity>>> getTaxes();

  /// Get a tax by ID
  Future<Result<TaxEntity>> getTaxById(int id);

  /// Sync taxes from remote to local
  Future<Result<void>> syncTaxes();

  /// Get taxes from local storage
  Future<Result<List<TaxEntity>>> getLocalTaxes();
}







