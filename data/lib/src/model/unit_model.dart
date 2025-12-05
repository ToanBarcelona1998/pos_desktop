import 'base_model.dart';

/// Unit data model
class UnitModel extends BaseModel {
  final int id;
  final int businessId;
  final String actualName;
  final String shortName;
  final int allowDecimal;
  final String? createdAt;
  final String? updatedAt;

  const UnitModel({
    required this.id,
    required this.businessId,
    required this.actualName,
    required this.shortName,
    this.allowDecimal = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      actualName: json['actual_name'] as String? ?? '',
      shortName: json['short_name'] as String? ?? '',
      allowDecimal: json['allow_decimal'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'actual_name': actualName,
      'short_name': shortName,
      'allow_decimal': allowDecimal,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}












