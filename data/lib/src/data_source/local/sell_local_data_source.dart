import 'package:sqflite/sqflite.dart';

import '../../model/sell_model.dart';
import 'database/database_helper.dart';

/// Local data source for sells using SQLite
abstract class SellLocalDataSource {
  /// Saves a complete sell (sell + lines + payments) atomically
  Future<int> saveSell({
    required Map<String, dynamic> sellData,
    required List<Map<String, dynamic>> sellLines,
    required List<Map<String, dynamic>> payments,
    required bool isFinalOrSuspended,
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

  /// Deletes a sell
  Future<void> deleteSell(int sellId);
}

/// Implementation of SellLocalDataSource
class SellLocalDataSourceImpl implements SellLocalDataSource {
  final DatabaseHelper _dbHelper;

  SellLocalDataSourceImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<int> saveSell({
    required Map<String, dynamic> sellData,
    required List<Map<String, dynamic>> sellLines,
    required List<Map<String, dynamic>> payments,
    required bool isFinalOrSuspended,
  }) async {
    final db = await _dbHelper.database;

    return await db.transaction((txn) async {
      // Remove shipping-related fields before inserting (like old code)
      Map<String, dynamic> cleanedSellData = Map.from(sellData)
        ..remove('shipping_charges')
        ..remove('shipping_details')
        ..remove('shipping_address')
        ..remove('shipping_status')
        ..remove('delivered_to');

      // Ensure is_synced is 0 for new sells
      cleanedSellData['is_synced'] = 0;

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

      // Update stock if final or suspended (like old code)
      if (isFinalOrSuspended && sellData['location_id'] != null) {
        for (var line in sellLines) {
          if (line['variation_id'] != null && line['quantity'] != null) {
            await txn.rawUpdate(
              '''
              UPDATE variations_location_details 
              SET qty_available = qty_available - ? 
              WHERE variation_id = ? AND location_id = ?
              ''',
              [
                line['quantity'],
                line['variation_id'],
                sellData['location_id'],
              ],
            );
          }
        }
      }

      return sellId;
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getUnsyncedSells() async {
    final db = await _dbHelper.database;
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
    final db = await _dbHelper.database;
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
    final db = await _dbHelper.database;
    return await db.query(
      'sell_lines',
      where: 'sell_id = ?',
      whereArgs: [sellId],
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getPayments(int sellId) async {
    final db = await _dbHelper.database;
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
    final db = await _dbHelper.database;

    // Remove shipping fields
    final cleanedUpdates = Map<String, dynamic>.from(updates)
      ..remove('shipping_charges')
      ..remove('shipping_details')
      ..remove('shipping_address')
      ..remove('shipping_status')
      ..remove('delivered_to');

    await db.update(
      'sell',
      cleanedUpdates,
      where: 'id = ?',
      whereArgs: [sellId],
    );

    // Update payment lines if provided
    if (updates.containsKey('payment_lines') &&
        updates['payment_lines'] is List) {
      // Delete existing payments
      await db.delete(
        'sell_payments',
        where: 'sell_id = ?',
        whereArgs: [sellId],
      );

      // Insert new payments
      final paymentLines = updates['payment_lines'] as List;
      for (var paymentLine in paymentLines) {
        await db.insert(
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
            'transaction_date': paymentLine['transaction_date'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getSuspendedSells() async {
    final db = await _dbHelper.database;
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
    final db = await _dbHelper.database;
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
  Future<void> deleteSell(int sellId) async {
    final db = await _dbHelper.database;
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





