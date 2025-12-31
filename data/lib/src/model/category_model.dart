import 'base_model.dart';

/// Category data model
class CategoryModel extends BaseModel {
  final int id;
  final String name;
  final int businessId;
  final String? shortCode;
  final int? parentId;
  final String? categoryType;
  final String? description;
  final String? slug;
  final List<CategoryModel> subCategories;
  final String? createdAt;
  final String? updatedAt;

  const CategoryModel({
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

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final subCategoriesJson = json['sub_categories'] as List<dynamic>?;
    final subCategories = subCategoriesJson
        ?.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList() ?? [];

    return CategoryModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
      businessId: int.parse(json['business_id'].toString()),
      shortCode: json['short_code'] as String?,
      parentId: int.tryParse(json['parent_id']?.toString() ?? ''),
      categoryType: json['category_type'] as String?,
      description: json['description'] as String?,
      slug: json['slug'] as String?,
      subCategories: subCategories,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'business_id': businessId,
      'short_code': shortCode,
      'parent_id': parentId,
      'category_type': categoryType,
      'description': description,
      'slug': slug,
      'sub_categories': subCategories.map((e) => e.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}














