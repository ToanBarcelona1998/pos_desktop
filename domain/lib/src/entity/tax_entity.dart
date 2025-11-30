import '../core/entity.dart';

/// Tax entity representing tax information
class TaxEntity extends Entity {
  final int id;
  final int businessId;
  final String name;
  final double amount;
  final bool isTaxGroup;
  final bool forTaxGroup;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  const TaxEntity({
    required this.id,
    required this.businessId,
    required this.name,
    required this.amount,
    this.isTaxGroup = false,
    this.forTaxGroup = false,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        amount,
        isTaxGroup,
        forTaxGroup,
        createdAt,
        updatedAt,
        deletedAt,
      ];
}





