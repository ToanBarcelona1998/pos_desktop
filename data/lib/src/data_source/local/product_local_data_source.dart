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

    // Match old query structure: JOIN with product_locations and variations_location_details
    String query = '''
      SELECT DISTINCT v.*, vld.qty_available
      FROM variations v
      JOIN product_locations pl 
        ON v.product_id = pl.product_id 
        AND pl.location_id = ?
      LEFT JOIN variations_location_details vld 
        ON v.variation_id = vld.variation_id 
        AND v.product_id = vld.product_id 
        AND vld.location_id = ?
      WHERE 1=1
    ''';

    List<dynamic> args = [locationId, locationId];

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query += ' AND (v.display_name LIKE ? OR v.sub_sku LIKE ?)';
      args.add('%$searchTerm%');
      args.add('%$searchTerm%');
    }

    query += ' ORDER BY v.variation_id LIMIT ? OFFSET ?';
    args.add(limit);
    args.add(offset * limit);

    final result = await db.rawQuery(query, args);

    return result.map((json) {
      // Ensure display_name is constructed if missing from DB
      final jsonMap = Map<String, dynamic>.from(json);
      if (jsonMap['display_name'] == null || jsonMap['display_name'].toString().isEmpty) {
        final productName = jsonMap['product_name']?.toString() ?? '';
        final productVariationName = jsonMap['product_variation_name']?.toString() ?? '';
        final variationName = jsonMap['variation_name']?.toString() ?? '';
        jsonMap['display_name'] = '$productName $productVariationName $variationName'.trim();
      }
      return ProductModel.fromJson(jsonMap);
    }).toList();
  }

  @override
  Future<void> saveProducts(List<ProductModel> products, int locationId) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      final processedProductIds = <int>{};

      for (final product in products) {
        // Construct display_name if not present (like old code)
        final productJson = product.toJson();
        if (productJson['display_name'] == null || productJson['display_name'].toString().isEmpty) {
          final productName = productJson['product_name']?.toString() ?? '';
          final productVariationName = productJson['product_variation_name']?.toString() ?? '';
          final variationName = productJson['variation_name']?.toString() ?? '';
          productJson['display_name'] = '$productName $productVariationName $variationName'.trim();
        }

        // Insert variation
        batch.insert(
          'variations',
          productJson,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Insert product_locations (only once per product_id)
        if (product.productId != null && !processedProductIds.contains(product.productId)) {
          batch.insert(
            'product_locations',
            {
              'product_id': product.productId,
              'location_id': locationId,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          processedProductIds.add(product.productId!);
        }

        // Insert location details if available
        if (product.qtyAvailable != null && product.productId != null && product.variationId != null) {
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
      await txn.delete('product_locations');
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
