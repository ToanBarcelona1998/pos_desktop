import '../core/entity.dart';

/// Business location entity
class LocationEntity extends Entity {
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
  final bool isActive;
  final List<String> paymentMethods;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LocationEntity({
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
    this.isActive = true,
    this.paymentMethods = const [],
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        locationId,
        landmark,
        city,
        state,
        country,
        zipCode,
        mobile,
        alternateNumber,
        email,
        website,
        isActive,
        paymentMethods,
        createdAt,
        updatedAt,
      ];
}








