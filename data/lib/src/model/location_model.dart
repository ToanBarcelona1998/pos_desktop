import 'base_model.dart';

/// Location data model
class LocationModel extends BaseModel {
  final int id;
  final int businessId;
  final String name;
  final String? locationId;
  final String? landmark;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? mobile;
  final String? alternateNumber;
  final String? email;
  final String? website;
  final int isActive;
  final List<dynamic>? paymentMethods;
  final String? createdAt;
  final String? updatedAt;

  const LocationModel({
    required this.id,
    required this.businessId,
    required this.name,
    this.locationId,
    this.landmark,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.mobile,
    this.alternateNumber,
    this.email,
    this.website,
    this.isActive = 1,
    this.paymentMethods,
    this.createdAt,
    this.updatedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      name: json['name'] as String,
      locationId: json['location_id'] as String?,
      landmark: json['landmark'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      zipCode: json['zip_code'] as String?,
      mobile: json['mobile'] as String?,
      alternateNumber: json['alternate_number'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      isActive: json['is_active'] as int? ?? 1,
      paymentMethods: json['payment_methods'] as List<dynamic>?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'location_id': locationId,
      'landmark': landmark,
      'city': city,
      'state': state,
      'country': country,
      'zip_code': zipCode,
      'mobile': mobile,
      'alternate_number': alternateNumber,
      'email': email,
      'website': website,
      'is_active': isActive,
      'payment_methods': paymentMethods,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}








