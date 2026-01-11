import 'package:sqflite/sqflite.dart';

import '../../model/cashier_session_model.dart';
import 'database/user_database_helper.dart';

/// Local data source for cashier sessions
abstract class CashierSessionLocalDataSource {
  /// Get active session for user and location
  Future<CashierSessionModel?> getActiveSession({
    required int userId,
    required int locationId,
  });

  /// Save session (check-in)
  Future<void> saveSession(CashierSessionModel session);

  /// Update session (check-out)
  Future<void> updateSession(CashierSessionModel session);

  /// Get unsynced sessions
  Future<List<CashierSessionModel>> getUnsyncedSessions();

  /// Mark session as synced
  Future<void> markSessionAsSynced(int sessionId);

  /// Delete session
  Future<void> deleteSession(int sessionId);
}

/// Implementation of CashierSessionLocalDataSource
class CashierSessionLocalDataSourceImpl
    implements CashierSessionLocalDataSource {
  final UserDatabaseHelper _dbHelper;

  CashierSessionLocalDataSourceImpl({
    UserDatabaseHelper? dbHelper,
  }) : _dbHelper = dbHelper ?? UserDatabaseHelper.instance;

  @override
  Future<CashierSessionModel?> getActiveSession({
    required int userId,
    required int locationId,
  }) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cashier_sessions',
      where: 'user_id = ? AND location_id = ? AND status = ?',
      whereArgs: [userId, locationId, 'active'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return CashierSessionModel.fromDatabaseJson(result.first);
  }

  @override
  Future<void> saveSession(CashierSessionModel session) async {
    final db = await _dbHelper.database;
    final data = session.toDatabaseJson();
    // Remove id if null to let auto-increment work
    if (data['id'] == null) {
      data.remove('id');
    }
    
    await db.insert(
      'cashier_sessions',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateSession(CashierSessionModel session) async {
    if (session.id == null) {
      throw Exception('Cannot update session without id');
    }

    final db = await _dbHelper.database;
    final data = session.toDatabaseJson();
    // Always update updated_at
    data['updated_at'] = DateTime.now().toIso8601String();
    // Remove id from update data
    data.remove('id');

    await db.update(
      'cashier_sessions',
      data,
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  @override
  Future<List<CashierSessionModel>> getUnsyncedSessions() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'cashier_sessions',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );

    return result
        .map((row) => CashierSessionModel.fromDatabaseJson(row))
        .toList();
  }

  @override
  Future<void> markSessionAsSynced(int sessionId) async {
    final db = await _dbHelper.database;
    await db.update(
      'cashier_sessions',
      {
        'is_synced': 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  @override
  Future<void> deleteSession(int sessionId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cashier_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }
}
