import 'package:sqflite/sqflite.dart';
import 'package:pos_final/models/database.dart';

class ContactModel {
  final int? id;
  final String name;
  final String? mobile;
  final String? prefix;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String type;

  ContactModel({
    this.id,
    required this.name,
    this.mobile,
    this.prefix,
    this.firstName,
    this.middleName,
    this.lastName,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.type = 'customer',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'prefix': prefix,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'address_line_1': addressLine1,
      'address_line_2': addressLine2,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'type': type,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'],
      name: map['name'],
      mobile: map['mobile'],
      prefix: map['prefix'],
      firstName: map['first_name'],
      middleName: map['middle_name'],
      lastName: map['last_name'],
      addressLine1: map['address_line_1'],
      addressLine2: map['address_line_2'],
      city: map['city'],
      state: map['state'],
      country: map['country'],
      zipCode: map['zip_code'],
      type: map['type'] ?? 'customer',
    );
  }
}

class Contact {
  final DbProvider _dbProvider = DbProvider();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _dbProvider.database;
    return _database!;
  }

  Future<List<Map<String, dynamic>>> get() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('contact');
    return maps;
  }

  Future<void> insertContact(ContactModel contact) async {
    final db = await database;
    await db.insert(
      'contact',
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> getCustomerDetailById(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contact',
      where: 'id = ?',
      whereArgs: [customerId],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return {'id': customerId, 'name': 'Unknown', 'mobile': ' - '};
  }
}