import '../core/result.dart';
import '../entity/sell_entity.dart';

/// Abstract repository for sell/transaction operations.
abstract class SellRepository {
  /// Creates a new sell transaction on server
  /// Returns the created sell from server with transaction_id and invoice_url
  Future<Result<SellEntity>> createSellOnServer(SellEntity sell);

  /// Updates an existing sell
  Future<Result<SellEntity>> updateSell(SellEntity sell);

  /// Deletes a sell from server
  Future<Result<void>> deleteSell(int id);

  /// Deletes a sell locally only
  Future<Result<void>> deleteSellLocally(int id);

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

  /// Saves sell locally with sync status and server response data
  Future<Result<SellEntity>> saveSellLocallyWithSyncData(
    SellEntity sell,
    SellEntity syncedSell,
  );

  /// Gets draft sells
  Future<Result<List<SellEntity>>> getDraftSells();

  /// Gets quotations
  Future<Result<List<SellEntity>>> getQuotations();

  /// Gets suspended sells
  Future<Result<List<SellEntity>>> getSuspendedSells();
}












