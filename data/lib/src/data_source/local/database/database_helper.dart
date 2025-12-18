import 'dart:io';

import 'package:domain/domain.dart';
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
  static const int _version = 11;

  /// Table creation scripts
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
    
    // Version 11: Add unique constraints and clean up duplicates
    if (oldVersion < 11) {
      await _migrateToVersion11(db);
    }
    // Add more version checks as needed
  }

  /// Migration to version 11: Add unique constraints and clean duplicates
  Future<void> _migrateToVersion11(Database db) async {
    await db.transaction((txn) async {
      // 1. Clean up duplicate records in system table
      await txn.execute('''
        DELETE FROM system 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM system 
          GROUP BY key, COALESCE(keyId, -1)
        )
      ''');

      // 2. Clean up duplicate records in variations table
      await txn.execute('''
        DELETE FROM variations 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM variations 
          GROUP BY product_id, variation_id
        )
      ''');

      // 3. Clean up duplicate records in variations_location_details
      await txn.execute('''
        DELETE FROM variations_location_details 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM variations_location_details 
          GROUP BY product_id, variation_id, location_id
        )
      ''');

      // 4. Clean up duplicate records in product_locations
      await txn.execute('''
        DELETE FROM product_locations 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM product_locations 
          GROUP BY product_id, location_id
        )
      ''');

      // 5. Clean up duplicate records in contact table
      await txn.execute('''
        DELETE FROM contact 
        WHERE rowid NOT IN (
          SELECT MAX(rowid) 
          FROM contact 
          GROUP BY id
        )
      ''');

      // 6. Clean up duplicate records in sell_payments
      await txn.execute('''
        DELETE FROM sell_payments 
        WHERE id NOT IN (
          SELECT MAX(id) 
          FROM sell_payments 
          WHERE payment_id IS NOT NULL
          GROUP BY sell_id, payment_id
        ) AND payment_id IS NOT NULL
      ''');

      // 7. Recreate system table with unique constraint
      await txn.execute('ALTER TABLE system RENAME TO system_old');
      await txn.execute(_createSystemTable);
      await txn.execute('''
        INSERT INTO system (id, keyId, key, value)
        SELECT id, keyId, key, value FROM system_old
      ''');
      await txn.execute('DROP TABLE system_old');

      // 8. Recreate contact table with unique constraint
      await txn.execute('ALTER TABLE contact RENAME TO contact_old');
      await txn.execute(_createContactTable);
      await txn.execute('''
        INSERT INTO contact (id, name, city, state, country, address_line_1, address_line_2, zip_code, mobile)
        SELECT id, name, city, state, country, address_line_1, address_line_2, zip_code, mobile FROM contact_old
      ''');
      await txn.execute('DROP TABLE contact_old');

      // 9. Recreate variations table with unique constraint
      await txn.execute('ALTER TABLE variations RENAME TO variations_old');
      await txn.execute(_createVariationTable);
      await txn.execute('''
        INSERT INTO variations (id, product_id, variation_id, product_name, product_variation_name, 
                                variation_name, display_name, sku, sub_sku, type, enable_stock, 
                                brand_id, unit_id, category_id, sub_category_id, tax_id, 
                                default_sell_price, sell_price_inc_tax, product_image_url, 
                                selling_price_group, product_description)
        SELECT id, product_id, variation_id, product_name, product_variation_name, 
               variation_name, display_name, sku, sub_sku, type, enable_stock, 
               brand_id, unit_id, category_id, sub_category_id, tax_id, 
               default_sell_price, sell_price_inc_tax, product_image_url, 
               selling_price_group, product_description 
        FROM variations_old
      ''');
      await txn.execute('DROP TABLE variations_old');

      // 10. Recreate variations_location_details with unique constraint
      await txn.execute('ALTER TABLE variations_location_details RENAME TO variations_location_details_old');
      await txn.execute(_createVariationLocationTable);
      await txn.execute('''
        INSERT INTO variations_location_details (id, product_id, variation_id, location_id, qty_available)
        SELECT id, product_id, variation_id, location_id, qty_available 
        FROM variations_location_details_old
      ''');
      await txn.execute('DROP TABLE variations_location_details_old');

      // 11. Recreate product_locations with unique constraint
      await txn.execute('ALTER TABLE product_locations RENAME TO product_locations_old');
      await txn.execute(_createProductLocationsTable);
      await txn.execute('''
        INSERT INTO product_locations (id, product_id, location_id)
        SELECT id, product_id, location_id FROM product_locations_old
      ''');
      await txn.execute('DROP TABLE product_locations_old');

      // 12. Recreate sell_payments with unique constraint
      await txn.execute('ALTER TABLE sell_payments RENAME TO sell_payments_old');
      await txn.execute(_createSellPaymentsTable);
      await txn.execute('''
        INSERT INTO sell_payments (id, sell_id, payment_id, method, amount, note, 
                                   account_id, is_return, card_number, card_type, 
                                   card_holder_name, transaction_date)
        SELECT id, sell_id, payment_id, method, amount, note, 
               account_id, is_return, card_number, card_type, 
               card_holder_name, transaction_date 
        FROM sell_payments_old
      ''');
      await txn.execute('DROP TABLE sell_payments_old');

      // 13. Create indexes for better query performance
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_system_key_keyId ON system(key, keyId)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_variations_product_variation ON variations(product_id, variation_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_variations_sku ON variations(sku)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_variations_sub_sku ON variations(sub_sku)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_variation_location ON variations_location_details(product_id, variation_id, location_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_product_locations ON product_locations(product_id, location_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_sell_lines_sell_id ON sell_lines(sell_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_sell_payments_sell_id ON sell_payments(sell_id)');
      await txn.execute('CREATE INDEX IF NOT EXISTS idx_contact_id ON contact(id)');
      
      Logger.logI('✅ Database migrated to version 11: Unique constraints added, duplicates cleaned, indexes created');
    });
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














