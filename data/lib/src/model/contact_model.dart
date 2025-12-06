import 'base_model.dart';

/// DTO for contact data
class ContactModel extends BaseModel {
  final int? id;
  final String? name;
  final String? mobile;
  final String? prefix;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? supplierBusinessName;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? type;

  const ContactModel({
    this.id,
    this.name,
    this.mobile,
    this.prefix,
    this.firstName,
    this.middleName,
    this.lastName,
    this.supplierBusinessName,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.type,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as int?,
      name: json['name'] as String?,
      mobile: json['mobile'] as String?,
      prefix: json['prefix'] as String?,
      firstName: json['first_name'] as String?,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String?,
      supplierBusinessName: json['supplier_business_name'] as String?,
      addressLine1: json['address_line_1'] as String?,
      addressLine2: json['address_line_2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zipCode: json['zip_code'] as String?,
      type: json['type'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (mobile != null) 'mobile': mobile,
      if (prefix != null) 'prefix': prefix,
      if (firstName != null) 'first_name': firstName,
      if (middleName != null) 'middle_name': middleName,
      if (lastName != null) 'last_name': lastName,
      if (supplierBusinessName != null)
        'supplier_business_name': supplierBusinessName,
      if (addressLine1 != null) 'address_line_1': addressLine1,
      if (addressLine2 != null) 'address_line_2': addressLine2,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (country != null) 'country': country,
      if (zipCode != null) 'zip_code': zipCode,
      if (type != null) 'type': type,
    };
  }
}














