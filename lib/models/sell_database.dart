// lib/models/sell_database.dart
import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'database.dart';
import 'system.dart';

class SellDatabase {
  late DbProvider dbProvider;

  SellDatabase() {
    dbProvider = DbProvider();
  }

  // Add item to cart
  Future<int> store(Map<String, dynamic> value) async {
    final db = await dbProvider.database;
    return db.insert('sell_lines', value, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Check presence of incomplete sellLine by variationId
  Future<List> checkSellLine(int varId, {sellId}) async {
    String where;
    (sellId == null) ? where = 'is_completed = ?' : where = 'sell_id = ?';
    var arg = (sellId == null) ? 0 : sellId;
    final db = await dbProvider.database;
    return db.query(
        'sell_lines',
        where: "$where and variation_id = ?",
        whereArgs: [arg, varId]
    );
  }

  // Fetch sell_lines by sell_id
  Future<List> getSellLines(sellId) async {
    final db = await dbProvider.database;
    return db.query(
        'sell_lines',
        columns: [
          'id', 'sell_id', 'product_id', 'variation_id', 'quantity',
          'unit_price', 'tax_rate_id', 'discount_amount',
          'discount_type', 'note', 'is_completed'
        ],
        where: "sell_id = ?",
        whereArgs: [sellId]
    );
  }

  // Fetch incomplete sellLine
  Future<List> getInCompleteLines(locationId, {sellId}) async {
    String where = sellId != null ? 'sell_id = $sellId' : 'is_completed = 0';
    String productLastSync = await System().getProductLastSync() ?? DateTime.now().toString();
    final db = await dbProvider.database;

    return db.rawQuery(
        '''
      SELECT DISTINCT SL.*, V.display_name AS name, V.sell_price_inc_tax, V.sub_sku, V.default_sell_price,
      CASE WHEN (qty_available IS NULL AND enable_stock = 0) THEN 9999 
           WHEN (qty_available IS NULL AND enable_stock = 1) THEN 0 
           ELSE (qty_available - COALESCE(
             (SELECT SUM(SL2.quantity) FROM sell_lines AS SL2 JOIN sell AS S on SL2.sell_id = S.id
              WHERE (SL2.is_completed = 0 OR S.transaction_date > ?) 
              AND S.location_id = ? AND SL2.variation_id=V.variation_id)
           , 0))
      END as "stock_available" 
      FROM "sell_lines" AS SL 
      JOIN "variations" AS V on (SL.variation_id = V.variation_id) 
      LEFT JOIN "variations_location_details" as VLD 
        ON SL.variation_id = VLD.variation_id 
        AND SL.product_id = VLD.product_id 
        AND VLD.location_id = ? 
      WHERE $where
      ''',
        [productLastSync, locationId, locationId]
    );
  }

  // Fetch sell_lines
  Future<List> get({isCompleted, sellId}) async {
    String where = sellId != null
        ? 'sell_id = $sellId'
        : 'is_completed = ${isCompleted ? 1 : 0}';
    final db = await dbProvider.database;

    return db.rawQuery(
        '''
      SELECT DISTINCT SL.*, V.display_name AS name, V.sell_price_inc_tax,
        V.sub_sku, V.default_sell_price 
      FROM "sell_lines" AS SL 
      JOIN "variations" AS V on (SL.variation_id = V.variation_id) 
      WHERE $where
      '''
    );
  }

  // Update sell_lines by variationId
  Future<int> update(sellLineId, value) async {
    final db = await dbProvider.database;
    return db.update(
        'sell_lines',
        value,
        where: 'id = ?',
        whereArgs: [sellLineId]
    );
  }

  // Update sell_lines after creating a sell
  Future<int> updateSellLine(Map<String, dynamic> value) async {
    final db = await dbProvider.database;
    return await db.transaction((txn) async {
      int response = await txn.update(
          'sell_lines',
          value,
          where: 'sell_id = ? AND is_completed = ?',
          whereArgs: [value['sell_id'], 0]
      );

      if (value['sell_id'] != null && value.containsKey('payment_lines')) {
        await storePaymentLines(value['payment_lines'], txn: txn);
      }

      // تحديث الكميات فقط للفواتير النهائية أو المعلقة
      if (value['sell_id'] != null) {
        List sell = await getSellBySellId(value['sell_id'], transaction: txn);
        if (sell.isNotEmpty && (sell[0]['status'] == 'final' || sell[0]['is_suspend'] == 1)) {
          List lines = await txn.query(
              'sell_lines',
              where: 'sell_id = ?',
              whereArgs: [value['sell_id']]
          );

          for (var line in lines) {
            await txn.rawUpdate(
                '''
              UPDATE variations_location_details 
              SET qty_available = qty_available - ? 
              WHERE variation_id = ? AND location_id = ?
              ''',
                [line['quantity'], line['variation_id'], sell[0]['location_id']]
            );
          }
        }
      }
      return response;
    });
  }

  // Delete sell_line
  Future<int> delete(int varId, int prodId, {sellId}) async {
    String where;
    List args;
    if (sellId == null) {
      where = 'is_completed = ? and variation_id = ? and product_id = ?';
      args = [0, varId, prodId];
    } else {
      where = 'sell_id = ? and variation_id = ? and product_id = ?';
      args = [sellId, varId, prodId];
    }

    final db = await dbProvider.database;
    return await db.delete('sell_lines', where: where, whereArgs: args);
  }

  // Delete sell_line by sellId
  Future<int> deleteSellLineBySellId(sellId) async {
    final db = await dbProvider.database;
    return await db.delete('sell_lines', where: 'sell_id = ?', whereArgs: [sellId]);
  }

  // Create sell
  Future<int> storeSell(Map<String, dynamic> value) async {
    final db = await dbProvider.database;
    // Remove shipping-related fields before storing
    Map<String, dynamic> cleanedValue = Map.from(value)
      ..remove('shipping_charges')
      ..remove('shipping_details')
      ..remove('shipping_address')
      ..remove('shipping_status')
      ..remove('delivered_to');
    return await db.insert('sell', cleanedValue, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Empty sells and sell details
  Future<void> deleteSellTables() async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete('sell');
      await txn.delete('sell_lines');
      await txn.delete('sell_payments');
    });
  }

  // Fetch current sales from database
  Future<List> getSells({bool? all}) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> sells = (all == true)
        ? await db.query('sell', orderBy: 'id DESC')
        : await db.query('sell', orderBy: 'id DESC', where: 'is_quotation = ?', whereArgs: [0]);

    // Remove shipping fields from returned data
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

  // Fetch transactionIds of synced sales
  Future<List> getTransactionIds() async {
    final db = await dbProvider.database;
    var response = await db.query(
        'sell',
        columns: ['transaction_id'],
        where: 'transaction_id != ?',
        whereArgs: ['null']
    );
    return response.map((e) => e['transaction_id']).toList();
  }

  // Fetch sales by sellId
  Future<List> getSellBySellId(sellId, {Transaction? transaction}) async {
    final db = transaction ?? await dbProvider.database;
    List<Map<String, dynamic>> sells = await db.query(
        'sell',
        columns: [
          'id', 'transaction_id', 'invoice_no', 'contact_id', 'location_id',
          'status', 'tax_rate_id', 'discount_amount', 'discount_type', 'invoice_amount',
          'change_return', 'sale_note', 'staff_note', 'shipping_charges', 'shipping_details',
          'shipping_address', 'shipping_status', 'delivered_to', 'pending_amount',
          'is_quotation', 'is_suspend', 'is_synced'
        ],
        where: 'id = ?',
        whereArgs: [sellId]
    );

    // Remove shipping fields from returned data
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

  // Fetch sales by TransactionId
  Future<List> getSellByTransactionId(transactionId) async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> sells = await db.query(
        'sell',
        columns: [
          'id', 'transaction_id', 'invoice_no', 'contact_id', 'location_id',
          'status', 'tax_rate_id', 'discount_amount', 'discount_type', 'invoice_amount',
          'change_return', 'sale_note', 'staff_note', 'shipping_charges', 'shipping_details',
          'shipping_address', 'shipping_status', 'delivered_to', 'pending_amount',
          'is_quotation', 'is_suspend', 'is_synced'
        ],
        where: 'transaction_id = ?',
        whereArgs: [transactionId]
    );

    // Remove shipping fields from returned data
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

  // Fetch not synced sales
  Future<List> getNotSyncedSells() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> sells = await db.query('sell', where: 'is_synced = 0');

    // Remove shipping fields from returned data
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

  // Fetch suspended sales
  Future<List> getSuspendedSells() async {
    final db = await dbProvider.database;
    List<Map<String, dynamic>> sells = await db.query(
        'sell',
        where: 'is_suspend = ?',
        whereArgs: [1],
        orderBy: 'transaction_date DESC'
    );

    // Remove shipping fields from returned data
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

  // Update sale
  Future<int> updateSells(sellId, value) async {
    final db = await dbProvider.database;
    // Remove shipping-related fields before updating
    Map<String, dynamic> cleanedValue = Map.from(value)
      ..remove('shipping_charges')
      ..remove('shipping_details')
      ..remove('shipping_address')
      ..remove('shipping_status')
      ..remove('delivered_to');
    return await db.update('sell', cleanedValue, where: 'id = ?', whereArgs: [sellId]);
  }

  // Delete all lines where is_completed = 0
  Future<int> deleteInComplete() async {
    final db = await dbProvider.database;
    return await db.delete('sell_lines', where: 'is_completed = ?', whereArgs: [0]);
  }

  Future<String> countSellLines({isCompleted, sellId}) async {
    String where = sellId != null
        ? 'sell_id = $sellId'
        : 'is_completed = 0';
    final db = await dbProvider.database;
    var response = await db.rawQuery(
        'SELECT COUNT(*) AS counts FROM sell_lines WHERE $where'
    );
    return response[0]['counts'].toString();
  }

  // Delete a sell and corresponding data
  Future<void> deleteSell(int sellId) async {
    final db = await dbProvider.database;
    await db.transaction((txn) async {
      await txn.delete('sell', where: 'id = ?', whereArgs: [sellId]);
      await txn.delete('sell_lines', where: 'sell_id = ?', whereArgs: [sellId]);
      await txn.delete('sell_payments', where: 'sell_id = ?', whereArgs: [sellId]);
    });
  }

  // Add or update payment lines
  Future<int> storePaymentLines(List<Map<String, dynamic>> payments, {Transaction? txn}) async {
    int rowsAffected = 0;
    final db = txn ?? await dbProvider.database;

    for (var payment in payments) {
      if (payment['sell_id'] != null) {
        rowsAffected += await db.insert(
          'sell_payments',
          {
            'sell_id': payment['sell_id'],
            'method': payment['method'],
            'amount': payment['amount'],
            'note': payment['note'],
            'payment_id': payment['payment_id'],
            'is_return': payment['is_return'] ?? 0,
            'account_id': payment['account_id'],
            'card_number': payment['card_number'],
            'card_type': payment['card_type'],
            'card_holder_name': payment['card_holder_name'],
            'transaction_date': payment['transaction_date'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    return rowsAffected;
  }

  // New method to create complete sell atomically
  Future<int> createCompleteSell({
    required Map<String, dynamic> sellData,
    required List<Map<String, dynamic>> sellLines,
    required List<Map<String, dynamic>> payments,
    required bool isFinalOrSuspended,
  }) async {
    final db = await dbProvider.database;
    return await db.transaction((txn) async {
      // Remove shipping-related fields before inserting
      Map<String, dynamic> cleanedSellData = Map.from(sellData)
        ..remove('shipping_charges')
        ..remove('shipping_details')
        ..remove('shipping_address')
        ..remove('shipping_status')
        ..remove('delivered_to');

      // Insert sell
      int sellId = await txn.insert('sell', cleanedSellData, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert sell lines
      for (var line in sellLines) {
        line['sell_id'] = sellId;
        await txn.insert('sell_lines', line, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Insert payments
      await storePaymentLines(payments.map((p) {
        p['sell_id'] = sellId;
        return p;
      }).toList(), txn: txn);

      // Update sell lines to completed
      await txn.update(
        'sell_lines',
        {'is_completed': isFinalOrSuspended ? 1 : 0},
        where: 'sell_id = ?',
        whereArgs: [sellId],
      );

      // Update stock if final or suspended
      if (isFinalOrSuspended) {
        for (var line in sellLines) {
          await txn.rawUpdate(
            '''
            UPDATE variations_location_details 
            SET qty_available = qty_available - ? 
            WHERE variation_id = ? AND location_id = ?
            ''',
            [line['quantity'], line['variation_id'], sellData['location_id']],
          );
        }
      }

      return sellId;
    });
  }
}