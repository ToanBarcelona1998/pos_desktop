import '../core/entity.dart';

/// Business entity for layout bill
final class LayoutBillBusinessEntity extends Entity {
  final String name;
  final String? logo;
  final String? cachedLogoPath;
  final String? mobile;
  final String? alternateNumber;
  final String? email;

  const LayoutBillBusinessEntity({
    required this.name,
    this.logo,
    this.cachedLogoPath,
    this.mobile,
    this.alternateNumber,
    this.email,
  });

  @override
  List<Object?> get props => [
        name,
        logo,
        cachedLogoPath,
        mobile,
        alternateNumber,
        email,
      ];
}

/// Location entity for layout bill
final class LayoutBillLocationEntity extends Entity {
  final int id;
  final String name;
  final String? landmark;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? mobile;
  final String? alternateNumber;
  final String? email;
  final String? website;

  const LayoutBillLocationEntity({
    required this.id,
    required this.name,
    this.landmark,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.mobile,
    this.alternateNumber,
    this.email,
    this.website,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        landmark,
        city,
        state,
        country,
        zipCode,
        mobile,
        alternateNumber,
        email,
        website,
      ];
}

/// Layout bill entity containing all bill layout information
final class LayoutBillEntity extends Entity {
  final LayoutBillLocationEntity location;
  final LayoutBillBusinessEntity business;

  const LayoutBillEntity({
    required this.location,
    required this.business,
  });

  @override
  List<Object?> get props => [
        location,
        business,

      ];
}

