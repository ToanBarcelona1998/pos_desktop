import 'base_model.dart';

/// DTO for brand data
class BrandModel extends BaseModel {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final int createdBy;
  final int? useForRepair;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  const BrandModel({
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

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: int.parse(json['id'].toString()),
      businessId: int.parse(json['business_id'].toString()),
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: int.parse(json['created_by'].toString()),
      useForRepair: int.tryParse(json['use_for_repair']?.toString() ?? ''),
      deletedAt: json['deleted_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      if (description != null) 'description': description,
      'created_by': createdBy,
      if (useForRepair != null) 'use_for_repair': useForRepair,
      if (deletedAt != null) 'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}














