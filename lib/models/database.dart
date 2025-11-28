import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_final/config.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbProvider {
  DbProvider();
  DbProvider._createInstance();
  static final DbProvider db = DbProvider._createInstance();
  static Database? _database;

  String createSystemTable =
      "CREATE TABLE system (id INTEGER PRIMARY KEY AUTOINCREMENT, keyId INTEGER DEFAULT null,"
      " key TEXT, value TEXT)";

  String createContactTable =
      "CREATE TABLE contact (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, city TEXT, state TEXT,"
      " country TEXT, address_line_1 TEXT, address_line_2 TEXT, zip_code TEXT, mobile TEXT)";

  String createVariationTable =
      "CREATE TABLE variations (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER,"
      " variation_id INTEGER, product_name TEXT, product_variation_name TEXT, variation_name TEXT,"
      " display_name TEXT, sku TEXT, sub_sku TEXT, type TEXT, enable_stock INTEGER,"
      " brand_id INTEGER, unit_id INTEGER, category_id INTEGER, sub_category_id INTEGER,"
      " tax_id INTEGER, default_sell_price REAL, sell_price_inc_tax REAL, product_image_url TEXT,"
      " selling_price_group BLOB DEFAULT null, product_description TEXT)";

  String createVariationByLocationTable =
      "CREATE TABLE variations_location_details (id INTEGER PRIMARY KEY AUTOINCREMENT,"
      " product_id INTEGER, variation_id INTEGER, location_id INTEGER, qty_available REAL)";

  String createProductAvailableInLocationTable =
      "CREATE TABLE product_locations (id INTEGER PRIMARY KEY AUTOINCREMENT, product_id INTEGER,"
      " location_id INTEGER)";

  String createSellTable =
      "CREATE TABLE sell (id INTEGER PRIMARY KEY AUTOINCREMENT, transaction_date TEXT, invoice_no TEXT,"
      " contact_id INTEGER, location_id INTEGER, status TEXT, tax_rate_id INTEGER, discount_amount REAL,"
      " discount_type TEXT, sale_note TEXT, staff_note TEXT, shipping_details TEXT, shipping_address TEXT,"
      " shipping_status TEXT, delivered_to TEXT, is_quotation INTEGER DEFAULT 0, is_suspend INTEGER DEFAULT 0,"
      " shipping_charges REAL DEFAULT 0.00, invoice_amount REAL, change_return REAL DEFAULT 0.00,"
      " pending_amount REAL DEFAULT 0.00, is_synced INTEGER, transaction_id INTEGER DEFAULT null,"
      " invoice_url TEXT DEFAULT null)";

  String createSellLineTable =
      "CREATE TABLE sell_lines (id INTEGER PRIMARY KEY AUTOINCREMENT, sell_id INTEGER,"
      " product_id INTEGER, variation_id INTEGER, quantity REAL, unit_price REAL,"
      " tax_rate_id INTEGER, discount_amount REAL DEFAULT 0.0, discount_type TEXT DEFAULT 'fixed',"
      " note TEXT, is_completed INTEGER)";

  String createSellPaymentsTable =
      "CREATE TABLE sell_payments (id INTEGER PRIMARY KEY AUTOINCREMENT, sell_id INTEGER,"
      " payment_id INTEGER DEFAULT null, method TEXT, amount REAL, note TEXT,"
      " account_id INTEGER DEFAULT null, is_return INTEGER DEFAULT 0, card_number TEXT,"
      " card_type TEXT, card_holder_name TEXT, transaction_date TEXT)";

  Future<Database> get database async {
    _database ??= await initializeDatabase(Config.userId);
    return _database!;
  }

  int currVersion = 10;

  Future<Database> initializeDatabase(loginUserId) async {
    Directory posDirectory = await getApplicationDocumentsDirectory();
    String path = join('${posDirectory.path}PosDemo$loginUserId.db');

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      return await databaseFactoryFfi.openDatabase(path,
          options: OpenDatabaseOptions(
            version: currVersion,
            onCreate: (db, version) async {
              await db.execute(createSystemTable);
              await db.execute(createContactTable);
              await db.execute(createVariationTable);
              await db.execute(createVariationByLocationTable);
              await db.execute(createProductAvailableInLocationTable);
              await db.execute(createSellTable);
              await db.execute(createSellLineTable);
              await db.execute(createSellPaymentsTable);
            },
            onUpgrade: (db, oldVersion, newVersion) async {
              if (oldVersion < 2) {
                try {
                  await db.execute("ALTER TABLE sell_lines RENAME TO prev_sell_line;");
                  await db.execute(createSellLineTable);
                  await db.execute("INSERT INTO sell_lines SELECT * FROM prev_sell_line;");
                } catch (e) {
                  print('Error upgrading to version 2: $e');
                }
              }
              if (oldVersion < 3) {
                try {
                  await db.execute("ALTER TABLE variations RENAME TO prev_variations;");
                  await db.execute(createVariationTable);
                  await db.execute("INSERT INTO variations SELECT * FROM prev_variations;");
                } catch (e) {
                  print('Error upgrading to version 3: $e');
                }
              }
              if (oldVersion < 4) {
                try {
                  await db.execute(createContactTable);
                } catch (e) {
                  print('Error upgrading to version 4: $e');
                }
              }
              if (oldVersion < 5) {
                try {
                  await db.execute("ALTER TABLE sell ADD COLUMN invoice_url TEXT DEFAULT null;");
                } catch (e) {
                  print('Error upgrading to version 5: $e');
                }
              }
              if (oldVersion < 6) {
                try {
                  await db.execute("ALTER TABLE sell_payments ADD COLUMN account_id INTEGER DEFAULT null;");
                } catch (e) {
                  print('Error upgrading to version 6: $e');
                }
              }
              if (oldVersion < 7) {
                try {
                  await db.execute("ALTER TABLE sell ADD COLUMN shipping_address TEXT;");
                  await db.execute("ALTER TABLE sell ADD COLUMN shipping_status TEXT;");
                  await db.execute("ALTER TABLE sell ADD COLUMN delivered_to TEXT;");
                  await db.execute("ALTER TABLE sell ADD COLUMN is_suspend INTEGER DEFAULT 0;");
                } catch (e) {
                  print('Error upgrading to version 7: $e');
                }
              }
              if (oldVersion < 8) {
                try {
                  await db.execute("ALTER TABLE sell_lines ADD COLUMN discount_amount REAL DEFAULT 0.0;");
                  await db.execute("ALTER TABLE sell_lines ADD COLUMN discount_type TEXT DEFAULT 'fixed';");
                } catch (e) {
                  print('Error upgrading to version 8: $e');
                }
              }
              if (oldVersion < 9) {
                try {
                  await db.execute("ALTER TABLE sell_payments ADD COLUMN card_number TEXT;");
                  await db.execute("ALTER TABLE sell_payments ADD COLUMN card_type TEXT;");
                  await db.execute("ALTER TABLE sell_payments ADD COLUMN card_holder_name TEXT;");
                  await db.execute("ALTER TABLE sell_payments ADD COLUMN transaction_date TEXT;");
                } catch (e) {
                  print('Error upgrading to version 9: $e');
                }
              }
              if (oldVersion < 10) {
                // Additional future upgrades can be added here
                print('Upgrading to version 10 - No changes needed');
              }
              await db.setVersion(currVersion);
            },
          ));
    }

    return await openDatabase(
      path,
      version: currVersion,
      onCreate: (Database db, int version) async {
        await db.execute(createSystemTable);
        await db.execute(createContactTable);
        await db.execute(createVariationTable);
        await db.execute(createVariationByLocationTable);
        await db.execute(createProductAvailableInLocationTable);
        await db.execute(createSellTable);
        await db.execute(createSellLineTable);
        await db.execute(createSellPaymentsTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE sell_lines RENAME TO prev_sell_line;");
            await db.execute(createSellLineTable);
            await db.execute("INSERT INTO sell_lines SELECT * FROM prev_sell_line;");
          } catch (e) {
            print('Error upgrading to version 2: $e');
          }
        }
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE variations RENAME TO prev_variations;");
            await db.execute(createVariationTable);
            await db.execute("INSERT INTO variations SELECT * FROM prev_variations;");
          } catch (e) {
            print('Error upgrading to version 3: $e');
          }
        }
        if (oldVersion < 4) {
          try {
            await db.execute(createContactTable);
          } catch (e) {
            print('Error upgrading to version 4: $e');
          }
        }
        if (oldVersion < 5) {
          try {
            await db.execute("ALTER TABLE sell ADD COLUMN invoice_url TEXT DEFAULT null;");
          } catch (e) {
            print('Error upgrading to version 5: $e');
          }
        }
        if (oldVersion < 6) {
          try {
            await db.execute("ALTER TABLE sell_payments ADD COLUMN account_id INTEGER DEFAULT null;");
          } catch (e) {
            print('Error upgrading to version 6: $e');
          }
        }
        if (oldVersion < 7) {
          try {
            await db.execute("ALTER TABLE sell ADD COLUMN shipping_address TEXT;");
            await db.execute("ALTER TABLE sell ADD COLUMN shipping_status TEXT;");
            await db.execute("ALTER TABLE sell ADD COLUMN delivered_to TEXT;");
            await db.execute("ALTER TABLE sell ADD COLUMN is_suspend INTEGER DEFAULT 0;");
          } catch (e) {
            print('Error upgrading to version 7: $e');
          }
        }
        if (oldVersion < 8) {
          try {
            await db.execute("ALTER TABLE sell_lines ADD COLUMN discount_amount REAL DEFAULT 0.0;");
            await db.execute("ALTER TABLE sell_lines ADD COLUMN discount_type TEXT DEFAULT 'fixed';");
          } catch (e) {
            print('Error upgrading to version 8: $e');
          }
        }
        if (oldVersion < 9) {
          try {
            await db.execute("ALTER TABLE sell_payments ADD COLUMN card_number TEXT;");
            await db.execute("ALTER TABLE sell_payments ADD COLUMN card_type TEXT;");
            await db.execute("ALTER TABLE sell_payments ADD COLUMN card_holder_name TEXT;");
            await db.execute("ALTER TABLE sell_payments ADD COLUMN transaction_date TEXT;");
          } catch (e) {
            print('Error upgrading to version 9: $e');
          }
        }
        if (oldVersion < 10) {
          // Additional future upgrades can be added here
          print('Upgrading to version 10 - No changes needed');
        }
        await db.setVersion(currVersion);
      },
    );
  }

  Future<List<Map<String, dynamic>>> getProducts(int locationId, {String searchTerm = '', int offset = 0, int limit = 10}) async {
    final db = await database;
    String query = '''
      SELECT DISTINCT v.*, vld.qty_available
      FROM variations v
      LEFT JOIN variations_location_details vld ON v.variation_id = vld.variation_id AND v.product_id = vld.product_id AND vld.location_id = ?
      WHERE vld.location_id = ? OR vld.location_id IS NULL
    ''';
    List<dynamic> args = [locationId, locationId];

    if (searchTerm.isNotEmpty) {
      query += ' AND (v.display_name LIKE ? OR v.sku LIKE ?)';
      args.add('%$searchTerm%');
      args.add('%$searchTerm%');
    }

    query += ' ORDER BY v.variation_id LIMIT ? OFFSET ?';
    args.add(limit);
    args.add(offset * limit);

    final result = await db.rawQuery(query, args);
    return result.isNotEmpty ? result : [];
  }

  Future<void> clearProductsCache() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('variations');
      await txn.delete('variations_location_details');
    });
  }

  Future<bool> needsProductsUpdate() async {
    final db = await database;
    final result = await db.rawQuery("SELECT value FROM system WHERE key = 'products_last_sync'");
    if (result.isEmpty) return true;
    final lastSync = DateTime.tryParse(result.first['value'] as String? ?? '');
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inMinutes > 10;
  }

  Future<void> updateProductsLastSync() async {
    final db = await database;
    await db.insert(
      'system',
      {'key': 'products_last_sync', 'value': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}