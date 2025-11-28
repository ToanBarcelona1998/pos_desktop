import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../apis/system.dart';
import '../models/contact_model.dart';
import 'database.dart';

class System {
  late DbProvider dbProvider;

  System() {
    dbProvider = DbProvider();
  }

  // Store system data
  Future<int> insert(String key, dynamic value, [int? keyId]) async {
    final db = await dbProvider.database;
    var data = {'key': key, 'keyId': keyId, 'value': jsonEncode(value)};
    var response = await db.insert('system', data, conflictAlgorithm: ConflictAlgorithm.replace);
    return response;
  }

  // Save user details
  Future<int> insertUserDetails(Map userDetails) async {
    final db = await dbProvider.database;
    var data = {'key': 'loggedInUser', 'value': jsonEncode(userDetails)};
    var response = await db.insert('system', data, conflictAlgorithm: ConflictAlgorithm.replace);
    return response;
  }

  // Store token
  Future<int> insertToken(String token) async {
    final db = await dbProvider.database;
    var data = {'key': 'token', 'value': token};
    var response = await db.insert('system', data, conflictAlgorithm: ConflictAlgorithm.replace);
    print('Token inserted into DB: $token'); // Added: Log the token insertion for debugging
    return response;
  }

  // Insert or update product last sync datetime
  Future<void> insertProductLastSyncDateTimeNow() async {
    final db = await dbProvider.database;
    String? lastSync = await getProductLastSync();

    if (lastSync == null) {
      var data = {
        'key': 'product_last_sync',
        'value': DateTime.now().toString()
      };
      await db.insert('system', data, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'system',
        {'value': DateTime.now().toString()},
        where: 'key = ?',
        whereArgs: ['product_last_sync'],
      );
    }
  }

  // Insert/update/get call_log_last_sync time
  Future<String?> callLogLastSyncDateTime([bool? insert]) async {
    final db = await dbProvider.database;
    var lastSyncDetail = await db.query(
      'system',
      where: 'key = ?',
      whereArgs: ['call_logs_last_sync'],
    );
    var lastSync = (lastSyncDetail.isNotEmpty) ? lastSyncDetail[0]['value'] as String? : null;

    if (insert == true) {
      var data = {
        'key': 'call_logs_last_sync',
        'value': DateTime.now().toString()
      };
      if (lastSync == null) {
        await db.insert('system', data, conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await db.update(
          'system',
          data,
          where: 'key = ?',
          whereArgs: ['call_logs_last_sync'],
        );
      }
    }
    return lastSync;
  }

  // Fetch product last sync datetime
  Future<String?> getProductLastSync() async {
    final db = await dbProvider.database;
    var result = await db.query(
      'system',
      where: 'key = ?',
      whereArgs: ['product_last_sync'],
    );
    return result.isNotEmpty ? result[0]['value'] as String? : null;
  }

  // Fetch token
  Future<String> getToken() async {
    final db = await dbProvider.database;
    var result = await db.query(
      'system',
      where: 'key = ?',
      whereArgs: ['token'],
    );
    String? token = result.isNotEmpty ? result[0]['value'] as String? : '';
    print('Retrieved Token from DB: $token'); // Added: Log the retrieved token for debugging
    if (token == null || token.isEmpty) {
      print('Warning: No token found in DB or token is empty'); // Added: Warning log if token is missing
    }
    return token ?? '';
  }

  // Return permission list
  Future<List> getPermission() async {
    var result = await get('loggedInUser');
    if (result.containsKey('is_admin') && result['is_admin'] == true) {
      return ['all'];
    } else {
      List permissions = await get('user_permissions');
      return permissions.isNotEmpty ? permissions : [];
    }
  }

  // Return the list of categories
  Future<List> getCategories() async {
    var categories = await get('taxonomy');
    return categories.isNotEmpty ? categories : [];
  }

  // Return the list of sub categories
  Future<List<dynamic>> getSubCategories(int parentId) async {
    final db = await dbProvider.database;
    var subCategories = await db.query(
      'system',
      where: 'key = ? AND keyId = ?',
      whereArgs: ['sub_categories', parentId],
    );
    if (subCategories.isNotEmpty) {
      try {
        var value = subCategories[0]['value'] as String?;
        return value != null ? jsonDecode(value) as List<dynamic> : [];
      } catch (e) {
        print('Error decoding subCategories: $e');
        return [];
      }
    }
    return [];
  }

  // Return the list of brands
  Future<List> getBrands() async {
    var brands = await get('brand');
    return brands.isNotEmpty ? brands : [];
  }

  // Store permissions
  Future<void> storePermissions() async {
    final db = await dbProvider.database;
    var result = await get('loggedInUser');
    if (result.containsKey('all_permissions')) {
      var userData = {
        'key': 'user_permissions',
        'value': jsonEncode(result['all_permissions'])
      };
      await db.insert('system', userData, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // Return the list of payment accounts
  Future<List> getPaymentAccounts() async {
    var accounts = await get('payment_accounts');
    return accounts.isNotEmpty ? accounts : [];
  }

  // Return the list of invoice types
  Future<List<Map<String, dynamic>>> getInvoiceTypes() async {
    // Static list of invoice types for now; can be fetched from API if needed
    return [
      {'value': 'final', 'label': 'final', 'is_quotation': 0, 'is_suspend': 0},
      {'value': 'draft', 'label': 'draft', 'is_quotation': 0, 'is_suspend': 0},
      {'value': 'quotation', 'label': 'quotation', 'is_quotation': 1, 'is_suspend': 0},
      {'value': 'suspend', 'label': 'suspend', 'is_quotation': 0, 'is_suspend': 1},
    ];
  }

  // Get data (brandList, categoryList, taxRateList, locationList, permissionList, etc.)
  Future<dynamic> get(String key, [int? keyId]) async {
    final db = await dbProvider.database;
    String where = keyId != null ? 'key = ? AND keyId = ?' : 'key = ?';
    List<dynamic> whereArgs = keyId != null ? [key, keyId] : [key];
    List<Map<String, dynamic>> result = await db.query(
      'system',
      where: where,
      whereArgs: whereArgs,
    );
    dynamic response;
    if (result.isNotEmpty) {
      var val = result[0]['value'] as String?;
      if (val != null) {
        try {
          response = jsonDecode(val);
        } catch (e) {
          print('Error decoding $key: $e');
          response = [];
        }
        // If still a string after decoding, try decoding again (for double-encoded values)
        if (response is String) {
          try {
            response = jsonDecode(response);
          } catch (e) {
            print('Error double-decoding $key: $e');
            response = [];
          }
        }
      } else {
        response = [];
      }
    } else {
      response = [];
    }
    return response;
  }

  // Empty system table
  Future<int> empty() async {
    final db = await dbProvider.database;
    return await db.delete('system');
  }

  // Delete column from system table
  Future<int> delete(String colName) async {
    final db = await dbProvider.database;
    return await db.delete('system', where: 'key = ?', whereArgs: [colName]);
  }

  // Refresh permission list
  Future<void> refreshPermissionList() async {
    final db = await dbProvider.database;
    await db.delete('system', where: 'key = ?', whereArgs: ['user_permissions']);
    await Permissions().get();
  }

  // Refresh system data
  Future<void> refresh() async {
    final db = await dbProvider.database;
    List colNames = [
      'business',
      'user_permissions',
      'active-subscription',
      'payment_methods',
      'payment_method',
      'location',
      'tax',
      'brand',
      'taxonomy',
      'sub_categories',
      'payment_accounts',
      'invoice_types',
    ];
    Contact().emptyContact();
    for (var element in colNames) {
      await db.delete('system', where: 'key = ?', whereArgs: [element]);
    }
    await SystemApi().store();
  }

  // Fetch customers last sync datetime
  Future<String?> getCustomersLastSync() async {
    final db = await dbProvider.database;
    var lastSyncDetail = await db.query(
      'system',
      where: 'key = ?',
      whereArgs: ['customers_last_sync'],
    );
    return (lastSyncDetail.isNotEmpty) ? lastSyncDetail[0]['value'] as String? : null;
  }

  // Insert or update customers last sync datetime
  Future<void> insertCustomersLastSyncDateTimeNow() async {
    final db = await dbProvider.database;
    String? lastSync = await getCustomersLastSync();
    var data = {
      'key': 'customers_last_sync',
      'value': DateTime.now().toString()
    };
    if (lastSync == null) {
      await db.insert('system', data, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'system',
        {'value': DateTime.now().toString()},
        where: 'key = ?',
        whereArgs: ['customers_last_sync'],
      );
    }
  }
}