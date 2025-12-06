import '../core/entity.dart';

/// Category entity representing product category
class CategoryEntity extends Entity {
  final int id;
  final String name;
  final int businessId;
  final String? shortCode;
  final int? parentId;
  final String? categoryType;
  final String? description;
  final String? slug;
  final List<CategoryEntity> subCategories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.businessId,
    this.shortCode,
    this.parentId,
    this.categoryType,
    this.description,
    this.slug,
    this.subCategories = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get hasSubCategories => subCategories.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        name,
        businessId,
        shortCode,
        parentId,
        categoryType,
        description,
        slug,
        subCategories,
        createdAt,
        updatedAt,
      ];
}














