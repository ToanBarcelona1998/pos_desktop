import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'database/database_helper.dart';

/// Local data source for system data storage
abstract class SystemLocalDataSource {
  /// Insert data with a key
  Future<void> insert(String key, String value, [int? keyId]);

  /// Get data by key
  Future<dynamic> get(String key);

  /// Get data by key and keyId
  Future<dynamic> getByKeyId(String key, int keyId);

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
  Future<void> insert(String key, String value, [int? keyId]) async {
    final db = await _databaseHelper.database;

    // Use ConflictAlgorithm.replace to match old behavior
    await db.insert(
      'system',
      {
        'key': key,
        'keyId': keyId,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<dynamic> get(String key) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'system',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isEmpty) return null;

    final value = result.first['value'] as String?;
    if (value == null) return null;

    try {
      final decoded = jsonDecode(value);
      // Handle double-encoded values (like in old code)
      if (decoded is String) {
        try {
          return jsonDecode(decoded);
        } catch (_) {
          return decoded;
        }
      }
      return decoded;
    } catch (_) {
      return value;
    }
  }

  @override
  Future<dynamic> getByKeyId(String key, int keyId) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'system',
      where: 'key = ? AND keyId = ?',
      whereArgs: [key, keyId],
    );

    if (result.isEmpty) return null;

    final value = result.first['value'] as String?;
    if (value == null) return null;

    try {
      final decoded = jsonDecode(value);
      // Handle double-encoded values
      if (decoded is String) {
        try {
          return jsonDecode(decoded);
        } catch (_) {
          return decoded;
        }
      }
      return decoded;
    } catch (_) {
      return value;
    }
  }

  @override
  Future<void> delete(String key) async {
    final db = await _databaseHelper.database;

    await db.delete(
      'system',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> clearAll() async {
    final db = await _databaseHelper.database;

    await db.delete('system');
  }
}
