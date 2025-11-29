import '../core/entity.dart';

final class ContactEntity extends Entity {
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

  const ContactEntity({
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
    required this.type,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        mobile,
        prefix,
        firstName,
        middleName,
        lastName,
        addressLine1,
        addressLine2,
        city,
        state,
        country,
        zipCode,
        type,
      ];

  ContactEntity copyWith({
    int? id,
    String? name,
    String? mobile,
    String? prefix,
    String? firstName,
    String? middleName,
    String? lastName,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    String? type,
  }) {
    return ContactEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      prefix: prefix ?? this.prefix,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      type: type ?? this.type,
    );
  }

  /// Returns full name combining all name parts
  String get fullName {
    final parts = [prefix, firstName, middleName, lastName]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isEmpty ? name : parts.join(' ');
  }

  /// Returns full address
  String get fullAddress {
    final parts = [addressLine1, addressLine2, city, state, country, zipCode]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}
