import 'base_model.dart';

/// Tax data model
class TaxModel extends BaseModel {
  final int id;
  final int businessId;
  final String name;
  final double amount;
  final int isTaxGroup;
  final int forTaxGroup;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;

  const TaxModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.amount,
    this.isTaxGroup = 0,
    this.forTaxGroup = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory TaxModel.fromJson(Map<String, dynamic> json) {
    return TaxModel(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      name: json['name'] as String,
      amount: _parseDouble(json['amount']),
      isTaxGroup: json['is_tax_group'] as int? ?? 0,
      forTaxGroup: json['for_tax_group'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      deletedAt: json['deleted_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'amount': amount,
      'is_tax_group': isTaxGroup,
      'for_tax_group': forTaxGroup,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

