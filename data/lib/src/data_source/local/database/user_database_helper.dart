import 'dart:io';

import 'package:domain/domain.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// User database helper for user-specific data (sells, sell_lines, sell_payments)
class UserDatabaseHelper {
  static UserDatabaseHelper? _instance;
  static Database? _database;
  static int? _userId;
  static const int _version = 2;

  UserDatabaseHelper._();

  static UserDatabaseHelper get instance {
    _instance ??= UserDatabaseHelper._();
    return _instance!;
  }

  /// Table creation scripts (only user-specific tables)
  static const String _createSystemUserTable = '''
    CREATE TABLE system_user (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyId INTEGER DEFAULT null,
      key TEXT NOT NULL,
      value TEXT,
      UNIQUE(key, keyId)
    )
  ''';

  static const String _createSellTable = '''
    CREATE TABLE sell (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      transaction_date TEXT,
      invoice_no TEXT,
      contact_id INTEGER,
      location_id INTEGER,
      status TEXT,
      tax_rate_id INTEGER,
      discount_amount REAL,
      discount_type TEXT,
      sale_note TEXT,
      staff_note TEXT,
      shipping_details TEXT,
      shipping_address TEXT,
      shipping_status TEXT,
      delivered_to TEXT,
      is_quotation INTEGER DEFAULT 0,
      is_suspend INTEGER DEFAULT 0,
      shipping_charges REAL DEFAULT 0.00,
      invoice_amount REAL,
      change_return REAL DEFAULT 0.00,
      pending_amount REAL DEFAULT 0.00,
      is_synced INTEGER,
      transaction_id INTEGER DEFAULT null,
      invoice_url TEXT DEFAULT null
    )
  ''';

  static const String _createSellLineTable = '''
    CREATE TABLE sell_lines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sell_id INTEGER,
      product_id INTEGER,
      variation_id INTEGER,
      quantity REAL,
      unit_price REAL,
      tax_rate_id INTEGER,
      discount_amount REAL DEFAULT 0.0,
      discount_type TEXT DEFAULT 'fixed',
      note TEXT,
      is_completed INTEGER
    )
  ''';

  static const String _createSellPaymentsTable = '''
    CREATE TABLE sell_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sell_id INTEGER NOT NULL,
      payment_id INTEGER DEFAULT null,
      method TEXT,
      amount REAL,
      note TEXT,
      account_id INTEGER DEFAULT null,
      is_return INTEGER DEFAULT 0,
      card_number TEXT,
      card_type TEXT,
      card_holder_name TEXT,
      transaction_date TEXT,
      UNIQUE(sell_id, payment_id)
    )
  ''';

  static const String _createCashierSessionsTable = '''
    CREATE TABLE cashier_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      location_id INTEGER NOT NULL,
      opening_amount REAL NOT NULL,
      closing_amount TEXT,
      closing_amount_on_staff TEXT,
      total_card_slips TEXT,
      total_cheques TEXT,
      closing_note TEXT,
      denominations TEXT,
      start_time TEXT,
      end_time TEXT,
      status TEXT NOT NULL DEFAULT 'active',
      is_synced INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT
    )
  ''';

  /// Initializes the user database
  Future<Database> initUserDatabase(int userId) async {
    _userId = userId;
    _database = null; // Reset to force re-initialization

    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'PosUser$userId.db');

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      _database = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _version,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      _database = await openDatabase(
        path,
        version: _version,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }

    return _database!;
  }

  /// Gets the database instance
  Future<Database> get database async {
    if (_database != null && _userId != null) return _database!;
    throw Exception(
        'User database not initialized. Call initUserDatabase(userId) first.');
  }

  /// Creates user-specific tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createSystemUserTable);
    await db.execute(_createSellTable);
    await db.execute(_createSellLineTable);
    await db.execute(_createSellPaymentsTable);
    await db.execute(_createCashierSessionsTable);

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_system_user_key_keyId ON system_user(key, keyId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sell_lines_sell_id ON sell_lines(sell_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sell_payments_sell_id ON sell_payments(sell_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_cashier_sessions_user_location_status ON cashier_sessions(user_id, location_id, status)');

    Logger.logI('✅ User database created successfully for user $_userId');
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add cashier_sessions table
      await db.execute(_createCashierSessionsTable);
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_cashier_sessions_user_location_status ON cashier_sessions(user_id, location_id, status)');
      Logger.logI('✅ Added cashier_sessions table');
    }
    Logger.logI(
        'User database upgraded from version $oldVersion to $newVersion');
  }

  /// Closes the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _userId = null;
    }
  }

  /// Deletes the user database file
  Future<void> deleteUserDatabase(int userId) async {
    await close();

    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'PosUser$userId.db');
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
      Logger.logI('✅ User database deleted for user $userId');
    }
  }
}

