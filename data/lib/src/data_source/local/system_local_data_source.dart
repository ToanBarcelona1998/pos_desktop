import 'dart:convert';

import 'database/database_helper.dart';

/// Local data source for system data storage
abstract class SystemLocalDataSource {
  /// Insert data with a key
  Future<void> insert(String key, String value, [int? referenceId]);

  /// Get data by key
  Future<dynamic> get(String key);

  /// Get data by key and reference ID
  Future<dynamic> getByReference(String key, int referenceId);

  /// Delete data by key
  Future<void> delete(String key);

  /// Clear all system data
  Future<void> clearAll();
}

/// Implementation of [SystemLocalDataSource]
class SystemLocalDataSourceImpl implements SystemLocalDataSource {
  final DatabaseHelper _databaseHelper;

  const SystemLocalDataSourceImpl({
    required DatabaseHelper databaseHelper,
  }) : _databaseHelper = databaseHelper;

  @override
  Future<void> insert(String key, String value, [int? referenceId]) async {
    final db = await _databaseHelper.database;
    if (db == null) return;

    await db.insert(
      'system',
      {
        'key': key,
        'value': value,
        'reference_id': referenceId,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<dynamic> get(String key) async {
    final db = await _databaseHelper.database;
    if (db == null) return null;

    final result = await db.query(
      'system',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;

    final value = result.first['value'] as String?;
    if (value == null) return null;

    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  @override
  Future<dynamic> getByReference(String key, int referenceId) async {
    final db = await _databaseHelper.database;
    if (db == null) return null;

    final result = await db.query(
      'system',
      where: 'key = ? AND reference_id = ?',
      whereArgs: [key, referenceId],
    );

    if (result.isEmpty) return null;

    final value = result.first['value'] as String?;
    if (value == null) return null;

    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  @override
  Future<void> delete(String key) async {
    final db = await _databaseHelper.database;
    if (db == null) return;

    await db.delete(
      'system',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> clearAll() async {
    final db = await _databaseHelper.database;
    if (db == null) return;

    await db.delete('system');
  }
}

