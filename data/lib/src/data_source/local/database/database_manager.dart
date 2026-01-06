import 'package:domain/domain.dart';
import 'package:sqflite/sqflite.dart';

import 'global_database_helper.dart';
import 'user_database_helper.dart';

/// Manages both global and user databases
class DatabaseManager {
  final GlobalDatabaseHelper _globalDb;
  final UserDatabaseHelper _userDb;

  DatabaseManager({
    required GlobalDatabaseHelper globalDb,
    required UserDatabaseHelper userDb,
  })  : _globalDb = globalDb,
        _userDb = userDb;

  /// Get global database
  Future<Database> get globalDatabase => _globalDb.database;

  /// Get user database
  Future<Database> get userDatabase => _userDb.database;

  /// Initialize global database (only needs to be called once)
  Future<void> initializeGlobalDatabase() async {
    await _globalDb.initGlobalDatabase();
  }

  /// Initialize user database for a specific user
  Future<void> initializeUserDatabase(int userId) async {
    await _userDb.initUserDatabase(userId);
  }

  /// Initialize both databases
  Future<void> initialize(int userId) async {
    await initializeGlobalDatabase();
    await initializeUserDatabase(userId);
  }

  /// Close both databases
  Future<void> close() async {
    await _globalDb.close();
    await _userDb.close();
  }

  /// Delete user database (on logout)
  Future<void> deleteUserDatabase(int userId) async {
    await _userDb.deleteUserDatabase(userId);
  }
}

