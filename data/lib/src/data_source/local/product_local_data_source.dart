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
  /// [productsJson] is optional raw JSON data to extract variation_location_details array
  Future<void> saveProducts(
    List<ProductModel> products,
    int locationId, {
    List<Map<String, dynamic>>? productsJson,
  });

  /// Finds a product by SKU (exact match)
  Future<ProductModel?> findProductBySku({
    required int locationId,
    required String sku,
  });

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

    // Query variations with qty_available from variations_location_details for the specific location
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
  Future<void> saveProducts(
    List<ProductModel> products,
    int locationId, {
    List<Map<String, dynamic>>? productsJson,
  }) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final batch = txn.batch();
      final processedProductIds = <int>{};

      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        
        // Construct display_name if not present (like old code)
        final productJson = product.toJson();
        if (productJson['display_name'] == null || productJson['display_name'].toString().isEmpty) {
          final productName = productJson['product_name']?.toString() ?? '';
          final productVariationName = productJson['product_variation_name']?.toString() ?? '';
          final variationName = productJson['variation_name']?.toString() ?? '';
          productJson['display_name'] = '$productName $productVariationName $variationName'.trim();
        }

        // Remove qty_available from variations insert (it belongs in variations_location_details)
        final variationsJson = Map<String, dynamic>.from(productJson);
        variationsJson.remove('qty_available');

        // Insert variation
        batch.insert(
          'variations',
          variationsJson,
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

        // Save variation_location_details from raw JSON if available, otherwise use product.qtyAvailable
        if (productsJson != null && i < productsJson.length) {
          final rawJson = productsJson[i];
          final variationLocationDetails = rawJson['variation_location_details'];
          
          if (variationLocationDetails is List && variationLocationDetails.isNotEmpty) {
            // Save all location details from the array
            for (final detail in variationLocationDetails) {
              if (detail is Map<String, dynamic>) {
                final detailMap = Map<String, dynamic>.from(detail);
                final detailLocationId = detailMap['location_id'];
                final detailQtyAvailable = detailMap['qty_available'];
                
                if (detailLocationId != null && 
                    product.productId != null && 
                    product.variationId != null) {
                  batch.insert(
                    'variations_location_details',
                    {
                      'product_id': product.productId,
                      'variation_id': product.variationId,
                      'location_id': detailLocationId,
                      'qty_available': _parseDouble(detailQtyAvailable),
                    },
                    conflictAlgorithm: ConflictAlgorithm.replace,
                  );
                }
              }
            }
          } else if (product.qtyAvailable != null && 
                     product.productId != null && 
                     product.variationId != null) {
            // Fallback: save single qty_available for the requested location
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
        } else if (product.qtyAvailable != null && 
                   product.productId != null && 
                   product.variationId != null) {
          // Fallback: save single qty_available for the requested location
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
  Future<ProductModel?> findProductBySku({
    required int locationId,
    required String sku,
  }) async {
    final db = await _dbHelper.database;

    // Query variations with exact SKU match (sub_sku or sku)
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
      WHERE (v.sub_sku = ? OR v.sku = ?)
      LIMIT 1
    ''';

    final result = await db.rawQuery(query, [locationId, locationId, sku, sku]);

    if (result.isEmpty) return null;

    final jsonMap = Map<String, dynamic>.from(result.first);
    // Ensure display_name is constructed if missing from DB
    if (jsonMap['display_name'] == null || jsonMap['display_name'].toString().isEmpty) {
      final productName = jsonMap['product_name']?.toString() ?? '';
      final productVariationName = jsonMap['product_variation_name']?.toString() ?? '';
      final variationName = jsonMap['variation_name']?.toString() ?? '';
      jsonMap['display_name'] = '$productName $productVariationName $variationName'.trim();
    }
    return ProductModel.fromJson(jsonMap);
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
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
