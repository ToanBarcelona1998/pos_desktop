import 'dart:io';

import 'package:domain/domain.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Global database helper for shared data (products, contacts, variations, etc.)
class GlobalDatabaseHelper {
  static GlobalDatabaseHelper? _instance;
  static Database? _database;
  static const int _version = 1;
  static const String _dbName = 'PosGlobal.db';

  GlobalDatabaseHelper._();

  static GlobalDatabaseHelper get instance {
    _instance ??= GlobalDatabaseHelper._();
    return _instance!;
  }

  /// Table creation scripts (only global tables)
  static const String _createSystemTable = '''
    CREATE TABLE system (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      keyId INTEGER DEFAULT null,
      key TEXT NOT NULL,
      value TEXT,
      UNIQUE(key, keyId)
    )
  ''';

  static const String _createContactTable = '''
    CREATE TABLE contact (
      id INTEGER PRIMARY KEY,
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
      product_id INTEGER NOT NULL,
      variation_id INTEGER NOT NULL,
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
      product_description TEXT,
      UNIQUE(product_id, variation_id)
    )
  ''';

  static const String _createVariationLocationTable = '''
    CREATE TABLE variations_location_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      variation_id INTEGER NOT NULL,
      location_id INTEGER NOT NULL,
      qty_available REAL,
      UNIQUE(product_id, variation_id, location_id)
    )
  ''';

  static const String _createProductLocationsTable = '''
    CREATE TABLE product_locations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      product_id INTEGER NOT NULL,
      location_id INTEGER NOT NULL,
      UNIQUE(product_id, location_id)
    )
  ''';

  /// Initializes the global database
  Future<Database> initGlobalDatabase() async {
    if (_database != null) return _database!;

    final Directory documentsDirectory =
        await getApplicationDocumentsDirectory();
    final String path = join(documentsDirectory.path, _dbName);

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
    if (_database != null) return _database!;
    return await initGlobalDatabase();
  }

  /// Creates global tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createSystemTable);
    await db.execute(_createContactTable);
    await db.execute(_createVariationTable);
    await db.execute(_createVariationLocationTable);
    await db.execute(_createProductLocationsTable);

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_system_key_keyId ON system(key, keyId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_variations_product_variation ON variations(product_id, variation_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_variations_sku ON variations(sku)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_variations_sub_sku ON variations(sub_sku)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_variation_location ON variations_location_details(product_id, variation_id, location_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_product_locations ON product_locations(product_id, location_id)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_contact_id ON contact(id)');

    Logger.logI('✅ Global database created successfully');
  }

  /// Handles database upgrades
  Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Add migration logic here when needed
    Logger.logI(
        'Global database upgraded from version $oldVersion to $newVersion');
  }

  /// Closes the database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

