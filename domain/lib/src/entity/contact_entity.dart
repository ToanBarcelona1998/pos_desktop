final class ContactModel {
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

  const ContactModel({
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
}