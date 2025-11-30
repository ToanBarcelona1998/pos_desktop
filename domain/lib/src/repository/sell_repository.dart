import '../core/result.dart';
import '../entity/sell_entity.dart';

/// Abstract repository for sell/transaction operations.
abstract class SellRepository {
  /// Creates a new sell transaction
  Future<Result<SellEntity>> createSell(SellEntity sell);

  /// Updates an existing sell
  Future<Result<SellEntity>> updateSell(SellEntity sell);

  /// Deletes a sell
  Future<Result<void>> deleteSell(int id);

  /// Gets a sell by ID
  Future<Result<SellEntity>> getSellById(int id);

  /// Gets sells by transaction IDs
  Future<Result<List<SellEntity>>> getSellsByIds(List<int> ids);

  /// Gets all local (unsynced) sells
  Future<Result<List<SellEntity>>> getLocalSells();

  /// Syncs local sells to remote
  Future<Result<void>> syncSells();

  /// Saves sell locally
  Future<Result<SellEntity>> saveSellLocally(SellEntity sell);

  /// Gets draft sells
  Future<Result<List<SellEntity>>> getDraftSells();

  /// Gets quotations
  Future<Result<List<SellEntity>>> getQuotations();

  /// Gets suspended sells
  Future<Result<List<SellEntity>>> getSuspendedSells();
}




