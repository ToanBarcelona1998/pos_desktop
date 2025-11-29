import 'package:sqflite/sqflite.dart';

import '../../model/product_model.dart';
import 'database/database_helper.dart';

/// Local data source for products using SQLite
abstract class ProductLocalDataSource {
  /// Gets products from cache
  Future<List<ProductModel>> getProducts({
    required int locationId,
    int offset = 0,
    int limit = 10,
    String? searchTerm,
  });

  /// Saves products to cache
  Future<void> saveProducts(List<ProductModel> products, int locationId);

  /// Clears product cache
  Future<void> clearCache();

  /// Checks if cache needs update
  Future<bool> needsUpdate();

  /// Updates last sync time
  Future<void> updateLastSync();
}

/// Implementation of ProductLocalDataSource
class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  final DatabaseHelper _dbHelper;

  ProductLocalDataSourceImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<List<ProductModel>> getProducts({
    required int locationId,
    int offset = 0,
    int limit = 10,
    String? searchTerm,
  }) async {
    final db = await _dbHelper.database;

    String query = '''
      SELECT DISTINCT v.*, vld.qty_available
      FROM variations v
      LEFT JOIN variations_location_details vld 
        ON v.variation_id = vld.variation_id 
        AND v.product_id = vld.product_id 
        AND vld.location_id = ?
      WHERE vld.location_id = ? OR vld.location_id IS NULL
    ''';

    List<dynamic> args = [locationId, locationId];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query += ' AND (v.display_name LIKE ? OR v.sku LIKE ?)';
      args.add('%$searchTerm%');
      args.add('%$searchTerm%');
    }

    query += ' ORDER BY v.variation_id LIMIT ? OFFSET ?';
    args.add(limit);
    args.add(offset * limit);

    final result = await db.rawQuery(query, args);

    return result.map((json) => ProductModel.fromJson(json)).toList();
  }

  @override
  Future<void> saveProducts(List<ProductModel> products, int locationId) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final product in products) {
        // Insert variation
        batch.insert(
          'variations',
          product.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert location details if available
        if (product.qtyAvailable != null) {
          batch.insert(
            'variations_location_details',
            {
              'product_id': product.productId,
              'variation_id': product.variationId,
              'location_id': locationId,
              'qty_available': product.qtyAvailable,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> clearCache() async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('variations');
      await txn.delete('variations_location_details');
    });
  }

  @override
  Future<bool> needsUpdate() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      "SELECT value FROM system WHERE key = 'products_last_sync'",
    );

    if (result.isEmpty) return true;

    final lastSync = DateTime.tryParse(result.first['value'] as String? ?? '');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync).inMinutes > 10;
  }

  @override
  Future<void> updateLastSync() async {
    final db = await _dbHelper.database;
    await db.insert(
      'system',
      {
        'key': 'products_last_sync',
        'value': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

