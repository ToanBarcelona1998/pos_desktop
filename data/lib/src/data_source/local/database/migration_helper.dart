import 'package:domain/domain.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'global_database_helper.dart';
import 'user_database_helper.dart';

/// Helper for migrating data from old single database to new split databases
class MigrationHelper {
  /// Migrate data from old single database to new split databases
  static Future<void> migrateFromOldDatabase({
    required int userId,
  }) async {
    try {
      // Initialize old database helper
      final oldDbHelper = DatabaseHelper.instance;
      final oldDb = await oldDbHelper.initDatabase(userId);

      // Initialize new databases
      final globalDbHelper = GlobalDatabaseHelper.instance;
      final globalDb = await globalDbHelper.initGlobalDatabase();

      final userDbHelper = UserDatabaseHelper.instance;
      final userDb = await userDbHelper.initUserDatabase(userId);

      Logger.logI('🔄 Starting database migration for user $userId...');

      // 1. Migrate global tables to global database
      await _migrateGlobalTables(oldDb, globalDb);

      // 2. Migrate user-specific tables to user database
      await _migrateUserTables(oldDb, userDb);

      // 3. Split system table
      await _migrateSystemTable(oldDb, globalDb, userDb);

      Logger.logI('✅ Database migration completed successfully');
    } catch (e) {
      Logger.logE('❌ Database migration failed', e);
      rethrow;
    }
  }

  /// Migrate global tables (contact, variations, variations_location_details, product_locations)
  static Future<void> _migrateGlobalTables(
    Database oldDb,
    Database globalDb,
  ) async {
    await globalDb.transaction((txn) async {
      // Migrate contact table
      try {
        final contacts = await oldDb.query('contact');
        if (contacts.isNotEmpty) {
          final batch = txn.batch();
          for (final contact in contacts) {
            batch.insert(
              'contact',
              contact,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          Logger.logI('✅ Migrated ${contacts.length} contacts to global database');
        }
      } catch (e) {
        Logger.logE('Error migrating contacts', e);
      }

      // Migrate variations table
      try {
        final variations = await oldDb.query('variations');
        if (variations.isNotEmpty) {
          final batch = txn.batch();
          for (final variation in variations) {
            batch.insert(
              'variations',
              variation,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          Logger.logI('✅ Migrated ${variations.length} variations to global database');
        }
      } catch (e) {
        Logger.logE('Error migrating variations', e);
      }

      // Migrate variations_location_details table
      try {
        final variationLocations = await oldDb.query('variations_location_details');
        if (variationLocations.isNotEmpty) {
          final batch = txn.batch();
          for (final location in variationLocations) {
            batch.insert(
              'variations_location_details',
              location,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          Logger.logI('✅ Migrated ${variationLocations.length} variation locations to global database');
        }
      } catch (e) {
        Logger.logE('Error migrating variation locations', e);
      }

      // Migrate product_locations table
      try {
        final productLocations = await oldDb.query('product_locations');
        if (productLocations.isNotEmpty) {
          final batch = txn.batch();
          for (final location in productLocations) {
            batch.insert(
              'product_locations',
              location,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          Logger.logI('✅ Migrated ${productLocations.length} product locations to global database');
        }
      } catch (e) {
        Logger.logE('Error migrating product locations', e);
      }
    });
  }

  /// Migrate user-specific tables (sell, sell_lines, sell_payments)
  static Future<void> _migrateUserTables(
    Database oldDb,
    Database userDb,
  ) async {
    await userDb.transaction((txn) async {
      // Migrate sell table
      try {
        final sells = await oldDb.query('sell');
        if (sells.isNotEmpty) {
          final batch = txn.batch();
          for (final sell in sells) {
            batch.insert(
              'sell',
              sell,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          Logger.logI('✅ Migrated ${sells.length} sells to user database');
        }
      } catch (e) {
        Logger.logE('Error migrating sells', e);
      }

      // Migrate sell_lines table
      try {
        final sellLines = await oldDb.query('sell_lines');
        if (sellLines.isNotEmpty) {
          final batch = txn.batch();
          for (final line in sellLines) {
            batch.insert(
              'sell_lines',
              line,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          Logger.logI('✅ Migrated ${sellLines.length} sell lines to user database');
        }
      } catch (e) {
        Logger.logE('Error migrating sell lines', e);
      }

      // Migrate sell_payments table
      try {
        final payments = await oldDb.query('sell_payments');
        if (payments.isNotEmpty) {
          final batch = txn.batch();
          for (final payment in payments) {
            batch.insert(
              'sell_payments',
              payment,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          await batch.commit(noResult: true);
          Logger.logI('✅ Migrated ${payments.length} payments to user database');
        }
      } catch (e) {
        Logger.logE('Error migrating payments', e);
      }
    });
  }

  /// Split system table: global keys → global database, user keys → user database
  static Future<void> _migrateSystemTable(
    Database oldDb,
    Database globalDb,
    Database userDb,
  ) async {
    // Define global keys
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

    // Define user-specific keys
    const userKeys = [
      'token',
      'loggedInUser',
      'user_permissions',
    ];

    try {
      final systemData = await oldDb.query('system');

      if (systemData.isEmpty) return;

      // Migrate to global database
      await globalDb.transaction((txn) async {
        final globalBatch = txn.batch();
        int globalCount = 0;

        for (final row in systemData) {
          final key = row['key'] as String?;
          if (key != null && globalKeys.contains(key)) {
            globalBatch.insert(
              'system',
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            globalCount++;
          }
        }

        if (globalCount > 0) {
          await globalBatch.commit(noResult: true);
          Logger.logI('✅ Migrated $globalCount global system keys to global database');
        }
      });

      // Migrate to user database (system_user table)
      await userDb.transaction((txn) async {
        final userBatch = txn.batch();
        int userCount = 0;

        for (final row in systemData) {
          final key = row['key'] as String?;
          if (key != null && userKeys.contains(key)) {
            userBatch.insert(
              'system_user',
              row,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            userCount++;
          }
        }

        if (userCount > 0) {
          await userBatch.commit(noResult: true);
          Logger.logI('✅ Migrated $userCount user-specific system keys to user database');
        }
      });
    } catch (e) {
      Logger.logE('Error migrating system table', e);
    }
  }
}

