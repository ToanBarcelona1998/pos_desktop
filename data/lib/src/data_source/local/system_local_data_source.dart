import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'database/global_database_helper.dart';
import 'database/user_database_helper.dart';

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
  final GlobalDatabaseHelper _globalDbHelper;
  final UserDatabaseHelper _userDbHelper;

  const SystemLocalDataSourceImpl({
    required GlobalDatabaseHelper globalDbHelper,
    required UserDatabaseHelper userDbHelper,
  })  : _globalDbHelper = globalDbHelper,
        _userDbHelper = userDbHelper;

  /// Determine if key is global or user-specific
  bool _isGlobalKey(String key) {
    const globalKeys = [
      'brand',
      'taxonomy',
      'sub_categories',
      'payment_methods',
      'location',
      'payment_accounts',
      'active-subscription',
      'products_last_sync',
      'customers_last_sync',
      'call_logs_last_sync',
      'business',
    ];
    return globalKeys.contains(key);
  }

  @override
  Future<void> insert(String key, String value, [int? keyId]) async {
    if (_isGlobalKey(key)) {
      final db = await _globalDbHelper.database;
      await db.insert(
        'system',
        {
          'key': key,
          'keyId': keyId,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      final db = await _userDbHelper.database;
      await db.insert(
        'system_user',
        {
          'key': key,
          'keyId': keyId,
          'value': value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<dynamic> get(String key) async {
    Database db;
    String tableName;

    if (_isGlobalKey(key)) {
      db = await _globalDbHelper.database;
      tableName = 'system';
    } else {
      db = await _userDbHelper.database;
      tableName = 'system_user';
    }

    final result = await db.query(
      tableName,
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
    Database db;
    String tableName;

    if (_isGlobalKey(key)) {
      db = await _globalDbHelper.database;
      tableName = 'system';
    } else {
      db = await _userDbHelper.database;
      tableName = 'system_user';
    }

    final result = await db.query(
      tableName,
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
    if (_isGlobalKey(key)) {
      final db = await _globalDbHelper.database;
      await db.delete(
        'system',
        where: 'key = ?',
        whereArgs: [key],
      );
    } else {
      final db = await _userDbHelper.database;
      await db.delete(
        'system_user',
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  @override
  Future<void> clearAll() async {
    final globalDb = await _globalDbHelper.database;
    await globalDb.delete('system');

    final userDb = await _userDbHelper.database;
    await userDb.delete('system_user');
  }
}
