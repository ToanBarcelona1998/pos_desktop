import 'package:domain/domain.dart';
import 'package:sqflite/sqflite.dart';

import 'database/global_database_helper.dart';
import 'database/user_database_helper.dart';

/// Local data source for sells using SQLite
abstract class SellLocalDataSource {
  /// Saves a complete sell (sell + lines + payments) atomically
  Future<int> saveSell({
    required Map<String, dynamic> sellData,
    required List<Map<String, dynamic>> sellLines,
    required List<Map<String, dynamic>> payments,
    required bool isFinalOrSuspended,
    bool isSynced = false,
  });

  /// Gets unsynced sells
  Future<List<Map<String, dynamic>>> getUnsyncedSells();

  /// Gets sell by ID
  Future<Map<String, dynamic>?> getSellById(int sellId);

  /// Gets sell lines by sell ID
  Future<List<Map<String, dynamic>>> getSellLines(int sellId);

  /// Gets payments by sell ID
  Future<List<Map<String, dynamic>>> getPayments(int sellId);

  /// Updates sell after sync
  Future<void> updateSellAfterSync(
    int sellId,
    Map<String, dynamic> updates,
  );

  /// Gets suspended sells
  Future<List<Map<String, dynamic>>> getSuspendedSells();

  /// Gets quotations
  Future<List<Map<String, dynamic>>> getQuotations();

  /// Gets final sells (status = 'final' or 'pending)
  Future<List<Map<String, dynamic>>> getFinalSells();

  /// Deletes a sell
  Future<void> deleteSell(int sellId);
}

/// Implementation of SellLocalDataSource
class SellLocalDataSourceImpl implements SellLocalDataSource {
  final UserDatabaseHelper _userDbHelper;
  final GlobalDatabaseHelper _globalDbHelper;

  SellLocalDataSourceImpl({
    UserDatabaseHelper? userDbHelper,
    GlobalDatabaseHelper? globalDbHelper,
  })  : _userDbHelper = userDbHelper ?? UserDatabaseHelper.instance,
        _globalDbHelper = globalDbHelper ?? GlobalDatabaseHelper.instance;

  @override
  Future<int> saveSell({
    required Map<String, dynamic> sellData,
    required List<Map<String, dynamic>> sellLines,
    required List<Map<String, dynamic>> payments,
    required bool isFinalOrSuspended,
    bool isSynced = false,
  }) async {
    Logger.logI('💾 [SellLocalDataSource] Saving sell - isFinalOrSuspended: $isFinalOrSuspended, locationId: ${sellData['location_id']}');
    final db = await _userDbHelper.database;

    return await db.transaction((txn) async {
      // Remove shipping-related fields before inserting (like old code)
      Map<String, dynamic> cleanedSellData = Map.from(sellData)
        ..remove('shipping_charges')
        ..remove('shipping_details')
        ..remove('shipping_address')
        ..remove('shipping_status')
        ..remove('delivered_to');

      // Set is_synced based on parameter (if not already set in sellData)
      if (!cleanedSellData.containsKey('is_synced')) {
        cleanedSellData['is_synced'] = isSynced ? 1 : 0;
      }

      // Insert sell
      final sellId = await txn.insert(
        'sell',
        cleanedSellData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Insert sell lines
      for (var line in sellLines) {
        line['sell_id'] = sellId;
        await txn.insert(
          'sell_lines',
          line,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Insert payments
      for (var payment in payments) {
        payment['sell_id'] = sellId;
        await txn.insert(
          'sell_payments',
          {
            'sell_id': sellId,
            'method': payment['method'],
            'amount': payment['amount'],
            'note': payment['note'] ?? '',
            'account_id': payment['account_id'],
            'is_return': payment['is_return'] ?? 0,
            'card_number': payment['card_number'],
            'card_type': payment['card_type'],
            'card_holder_name': payment['card_holder_name'],
            'transaction_date': payment['transaction_date'] ?? sellData['transaction_date'],
            'payment_id': payment['payment_id'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Update sell lines to completed
      await txn.update(
        'sell_lines',
        {'is_completed': isFinalOrSuspended ? 1 : 0},
        where: 'sell_id = ?',
        whereArgs: [sellId],
      );

      return sellId;
    }).then((sellId) async {
      // Update stock in global database if final or suspended
      // This must be done AFTER user database transaction commits
      if (isFinalOrSuspended && sellData['location_id'] != null) {
        try {
          Logger.logI('📦 [SellLocalDataSource] Updating stock in global database for sellId: $sellId, locationId: ${sellData['location_id']}');
          final globalDb = await _globalDbHelper.database;
          
          for (var line in sellLines) {
            if (line['variation_id'] != null && line['quantity'] != null) {
              final variationId = line['variation_id'] as int;
              final quantity = line['quantity'] as num;
              final locationId = sellData['location_id'] as int;
              
              Logger.logI('📦 [SellLocalDataSource] Updating stock - variationId: $variationId, quantity: -$quantity, locationId: $locationId');
              
              await globalDb.rawUpdate(
                '''
                UPDATE variations_location_details 
                SET qty_available = qty_available - ? 
                WHERE variation_id = ? AND location_id = ?
                ''',
                [quantity, variationId, locationId],
              );
              
              Logger.logI('✅ [SellLocalDataSource] Stock updated successfully for variationId: $variationId');
            }
          }
          Logger.logI('✅ [SellLocalDataSource] All stock updates completed for sellId: $sellId');
        } catch (e) {
          Logger.logE('❌ [SellLocalDataSource] Failed to update stock in global database', e);
          // Continue even if stock update fails - sell is already saved
          // Stock can be synced from server later
        }
      }
      
      return sellId;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedSells() async {
    final db = await _userDbHelper.database;
    final sells = await db.query(
      'sell',
      where: 'is_synced = ?',
      whereArgs: [0],
      orderBy: 'id DESC',
    );

    // Remove shipping fields (like old code)
    return sells.map((sell) {
      return {
        ...sell,
        'shipping_charges': 0.0,
        'shipping_details': null,
        'shipping_address': null,
        'shipping_status': null,
        'delivered_to': null,
      };
    }).toList();
  }

  @override
  Future<Map<String, dynamic>?> getSellById(int sellId) async {
    final db = await _userDbHelper.database;
    final sells = await db.query(
      'sell',
      where: 'id = ?',
      whereArgs: [sellId],
      limit: 1,
    );

    if (sells.isEmpty) return null;

    // Remove shipping fields
    final sell = sells.first;
    return {
      ...sell,
      'shipping_charges': 0.0,
      'shipping_details': null,
      'shipping_address': null,
      'shipping_status': null,
      'delivered_to': null,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getSellLines(int sellId) async {
    final db = await _userDbHelper.database;
    return await db.query(
      'sell_lines',
      where: 'sell_id = ?',
      whereArgs: [sellId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPayments(int sellId) async {
    final db = await _userDbHelper.database;
    return await db.query(
      'sell_payments',
      where: 'sell_id = ?',
      whereArgs: [sellId],
    );
  }

  @override
  Future<void> updateSellAfterSync(
    int sellId,
    Map<String, dynamic> updates,
  ) async {
    final db = await _userDbHelper.database;

    // Wrap everything in a transaction for atomicity
    await db.transaction((txn) async {
      // Extract payment_lines before cleaning updates (it's not a sell table column)
      final paymentLinesValue = updates['payment_lines'];
      
      // Remove shipping fields and payment_lines (not sell table columns)
      final cleanedUpdates = Map<String, dynamic>.from(updates)
        ..remove('shipping_charges')
        ..remove('shipping_details')
        ..remove('shipping_address')
        ..remove('shipping_status')
        ..remove('delivered_to')
        ..remove('payment_lines');

      // Only update sell table if there are fields to update
      if (cleanedUpdates.isNotEmpty) {
        await txn.update(
          'sell',
          cleanedUpdates,
          where: 'id = ?',
          whereArgs: [sellId],
        );
      }

      // Update payment lines if provided
      if (paymentLinesValue != null) {
        // Handle both List and single Map cases
        List<Map<String, dynamic>> paymentLines;
        if (paymentLinesValue is List) {
          paymentLines = paymentLinesValue
              .map((item) => item is Map<String, dynamic>
                  ? item
                  : item is Map
                      ? Map<String, dynamic>.from(item)
                      : <String, dynamic>{})
              .where((item) => item.isNotEmpty)
              .toList();
        } else if (paymentLinesValue is Map<String, dynamic>) {
          paymentLines = [paymentLinesValue];
        } else if (paymentLinesValue is Map) {
          paymentLines = [Map<String, dynamic>.from(paymentLinesValue)];
        } else {
          // Invalid type, skip payment lines update
          return;
        }

        // Delete existing payments
        await txn.delete(
          'sell_payments',
          where: 'sell_id = ?',
          whereArgs: [sellId],
        );

        // Insert new payments
        for (var paymentLine in paymentLines) {
          if (paymentLine.isEmpty) {
            continue; // Skip invalid payment lines
          }
          
          await txn.insert(
            'sell_payments',
            {
              'sell_id': sellId,
              'method': paymentLine['method'],
              'amount': paymentLine['amount'],
              'note': paymentLine['note'] ?? '',
              'account_id': paymentLine['account_id'],
              'is_return': paymentLine['is_return'] ?? 0,
              'card_number': paymentLine['card_number'],
              'card_type': paymentLine['card_type'],
              'card_holder_name': paymentLine['card_holder_name'],
              'payment_id': paymentLine['id'],
              'transaction_date': paymentLine['transaction_date'] ?? paymentLine['paid_on'],
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getSuspendedSells() async {
    final db = await _userDbHelper.database;
    final sells = await db.query(
      'sell',
      where: 'is_suspend = ?',
      whereArgs: [1],
      orderBy: 'transaction_date DESC',
    );

    return sells.map((sell) {
      return {
        ...sell,
        'shipping_charges': 0.0,
        'shipping_details': null,
        'shipping_address': null,
        'shipping_status': null,
        'delivered_to': null,
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getQuotations() async {
    final db = await _userDbHelper.database;
    final sells = await db.query(
      'sell',
      where: 'is_quotation = ?',
      whereArgs: [1],
      orderBy: 'transaction_date DESC',
    );

    return sells.map((sell) {
      return {
        ...sell,
        'shipping_charges': 0.0,
        'shipping_details': null,
        'shipping_address': null,
        'shipping_status': null,
        'delivered_to': null,
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getFinalSells() async {
    final db = await _userDbHelper.database;
    final sells = await db.query(
      'sell',
      where: 'status IN (?, ?) AND is_suspend = ? AND is_quotation = ?',
      whereArgs: ['final', 'pending', 0, 0],
      orderBy: 'transaction_date DESC',
    );

    return sells.map((sell) {
      return {
        ...sell,
        'shipping_charges': 0.0,
        'shipping_details': null,
        'shipping_address': null,
        'shipping_status': null,
        'delivered_to': null,
      };
    }).toList();
  }

  @override
  Future<void> deleteSell(int sellId) async {
    final db = await _userDbHelper.database;
    await db.transaction((txn) async {
      await txn.delete('sell', where: 'id = ?', whereArgs: [sellId]);
      await txn.delete('sell_lines', where: 'sell_id = ?', whereArgs: [sellId]);
      await txn.delete(
        'sell_payments',
        where: 'sell_id = ?',
        whereArgs: [sellId],
      );
    });
  }
}








