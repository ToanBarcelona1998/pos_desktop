import '../core/entity.dart';

/// Unit entity representing measurement unit information
class UnitEntity extends Entity {
  final int id;
  final int businessId;
  final String actualName;
  final String shortName;
  final bool allowDecimal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UnitEntity({
    required this.id,
    required this.businessId,
    required this.actualName,
    required this.shortName,
    this.allowDecimal = false,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        actualName,
        shortName,
        allowDecimal,
        createdAt,
        updatedAt,
      ];
}









