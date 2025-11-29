import '../core/entity.dart';

final class BrandEntity extends Entity {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final int createdBy;
  final bool? useForRepair;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BrandEntity({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.createdBy,
    this.useForRepair,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        description,
        createdBy,
        useForRepair,
        deletedAt,
        createdAt,
        updatedAt,
      ];

  BrandEntity copyWith({
    int? id,
    int? businessId,
    String? name,
    String? description,
    int? createdBy,
    bool? useForRepair,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandEntity(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      useForRepair: useForRepair ?? this.useForRepair,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
