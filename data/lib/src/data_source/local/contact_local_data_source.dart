import 'package:sqflite/sqflite.dart';

import '../../model/contact_model.dart';
import 'database/global_database_helper.dart';

/// Local data source for contacts using SQLite
abstract class ContactLocalDataSource {
  /// Gets contacts from cache
  Future<List<ContactModel>> getContacts({String? type});

  /// Gets contact by ID
  Future<ContactModel?> getContactById(int id);

  /// Saves contacts to cache
  Future<void> saveContacts(List<ContactModel> contacts);

  /// Clears contact cache
  Future<void> clearCache();
}

/// Implementation of ContactLocalDataSource
class ContactLocalDataSourceImpl implements ContactLocalDataSource {
  final GlobalDatabaseHelper _dbHelper;

  ContactLocalDataSourceImpl({GlobalDatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? GlobalDatabaseHelper.instance;

  @override
  Future<List<ContactModel>> getContacts({String? type}) async {
    final db = await _dbHelper.database;

    // Database schema: id, name, city, state, country, address_line_1, address_line_2, zip_code, mobile
    // Note: type is not in the database schema, so we can't filter by type
    final result = await db.query('contact');

    return result.map((row) {
      // Map database row to ContactModel
      // Database has: id, name, city, state, country, address_line_1, address_line_2, zip_code, mobile
      return ContactModel(
        id: row['id'] as int?,
        name: row['name'] as String?,
        mobile: row['mobile'] as String?,
        addressLine1: row['address_line_1'] as String?,
        addressLine2: row['address_line_2'] as String?,
        city: row['city'] as String?,
        state: row['state'] as String?,
        country: row['country'] as String?,
        zipCode: row['zip_code'] as String?,
        type: type ?? 'customer', // Default to customer if not specified
      );
    }).toList();
  }

  @override
  Future<ContactModel?> getContactById(int id) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'contact',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return ContactModel(
      id: row['id'] as int?,
      name: row['name'] as String?,
      mobile: row['mobile'] as String?,
      addressLine1: row['address_line_1'] as String?,
      addressLine2: row['address_line_2'] as String?,
      city: row['city'] as String?,
      state: row['state'] as String?,
      country: row['country'] as String?,
      zipCode: row['zip_code'] as String?,
      type: 'customer', // Default type
    );
  }

  @override
  Future<void> saveContacts(List<ContactModel> contacts) async {
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final contact in contacts) {
        // Map ContactModel to database schema
        // Database expects: id, name, city, state, country, address_line_1, address_line_2, zip_code, mobile
        batch.insert(
          'contact',
          {
            if (contact.id != null) 'id': contact.id,
            'name': contact.name ?? contact.supplierBusinessName ?? '',
            'mobile': contact.mobile,
            'city': contact.city,
            'state': contact.state,
            'country': contact.country,
            'address_line_1': contact.addressLine1,
            'address_line_2': contact.addressLine2,
            'zip_code': contact.zipCode,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> clearCache() async {
    final db = await _dbHelper.database;
    await db.delete('contact');
  }
}
