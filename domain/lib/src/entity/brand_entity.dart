final class BrandEntity {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final int createdBy;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BrandEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.createdBy,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}