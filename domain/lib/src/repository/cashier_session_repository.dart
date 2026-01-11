import '../core/result.dart';
import '../entity/cashier_session_entity.dart';

/// Repository interface for cashier session operations
abstract class CashierSessionRepository {
  /// Get active session
  Future<Result<CashierSessionEntity?>> getActiveSession({
    required int userId,
    required int locationId,
  });

  /// Check-in (start session)
  Future<Result<CashierSessionEntity>> checkIn({
    required int locationId,
    required double amount,
    required int userId,
  });

  /// Check-out (end session)
  Future<Result<CashierSessionEntity>> checkOut({
    required double closingAmount,
    required double closingAmountOnStaff,
    required double totalCardSlips,
    required double totalCheques,
    required String closingNote,
    required Map<String, int> denominations,
    required int userId,
    required int locationId,
  });

  /// Sync unsynced sessions
  Future<Result<void>> syncUnsyncedSessions();

  /// Save session locally (for webview check-in cache)
  Future<Result<CashierSessionEntity>> saveSessionLocally({
    required int userId,
    required int locationId,
    required double openingAmount,
    required DateTime startTime,
    bool isSynced = true,
  });
}
