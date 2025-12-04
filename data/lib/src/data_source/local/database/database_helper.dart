import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;
  static int? _userId;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  /// Current database version
  static const int _version = 10;

  /// Table creation scripts
  static const String _createSystemTable = '''
    CREATE TABLE system (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyId INTEGER DEFAULT null,
      key TEXT,
      value TEXT
    )
  ''';

  static const String _createContactTable = '''
    CREATE TABLE contact (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      city TEXT,
      state TEXT,
      country TEXT,
      address_line_1 TEXT,
      address_line_2 TEXT,
      zip_code TEXT,
      mobile TEXT
    )
  ''';

  static const String _createVariationTable = '''
    CREATE TABLE variations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER,
      variation_id INTEGER,
      product_name TEXT,
      product_variation_name TEXT,
      variation_name TEXT,
      display_name TEXT,
      sku TEXT,
      sub_sku TEXT,
      type TEXT,
      enable_stock INTEGER,
      brand_id INTEGER,
      unit_id INTEGER,
      category_id INTEGER,
      sub_category_id INTEGER,
      tax_id INTEGER,
      default_sell_price REAL,
      sell_price_inc_tax REAL,
      product_image_url TEXT,
      selling_price_group BLOB DEFAULT null,
      product_description TEXT
    )
  ''';

  static const String _createVariationLocationTable = '''
    CREATE TABLE variations_location_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER,
      variation_id INTEGER,
      location_id INTEGER,
      qty_available REAL
    )
  ''';

  static const String _createProductLocationsTable = '''
    CREATE TABLE product_locations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER,
      location_id INTEGER
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
      sell_id INTEGER,
      payment_id INTEGER DEFAULT null,
      method TEXT,
      amount REAL,
      note TEXT,
      account_id INTEGER DEFAULT null,
      is_return INTEGER DEFAULT 0,
      card_number TEXT,
      card_type TEXT,
      card_holder_name TEXT,
      transaction_date TEXT
    )
  ''';

  /// Initializes the database
  Future<Database> initDatabase(int userId) async {
    _userId = userId;
    _database = null; // Reset to force re-initialization

    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'PosDemo$userId.db');

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: _version,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Gets the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase(_userId ?? 0);
    return _database!;
  }

  /// Creates tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createSystemTable);
    await db.execute(_createContactTable);
    await db.execute(_createVariationTable);
    await db.execute(_createVariationLocationTable);
    await db.execute(_createProductLocationsTable);
    await db.execute(_createSellTable);
    await db.execute(_createSellLineTable);
    await db.execute(_createSellPaymentsTable);
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration scripts for each version
    if (oldVersion < 2) {
      // Version 2 migrations
    }
    // Add more version checks as needed
  }

  /// Closes the database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Deletes the database
  Future<void> deleteDatabase(int userId) async {
    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, 'PosDemo$userId.db');
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
      _database = null;
    }
  }
}











