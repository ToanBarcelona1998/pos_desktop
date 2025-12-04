import 'base_model.dart';

/// Variation data model
class VariationModel extends BaseModel {
  final int id;
  final int productId;
  final String name;
  final String? subSku;
  final double defaultPurchasePrice;
  final double dppIncTax;
  final double profitPercent;
  final double defaultSellPrice;
  final double sellPriceIncTax;
  final int? variationValueId;
  final String? createdAt;
  final String? updatedAt;

  const VariationModel({
    required this.id,
    required this.productId,
    required this.name,
    this.subSku,
    required this.defaultPurchasePrice,
    required this.dppIncTax,
    required this.profitPercent,
    required this.defaultSellPrice,
    required this.sellPriceIncTax,
    this.variationValueId,
    this.createdAt,
    this.updatedAt,
  });

  factory VariationModel.fromJson(Map<String, dynamic> json) {
    return VariationModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      name: json['name'] as String? ?? '',
      subSku: json['sub_sku'] as String?,
      defaultPurchasePrice: _parseDouble(json['default_purchase_price']),
      dppIncTax: _parseDouble(json['dpp_inc_tax']),
      profitPercent: _parseDouble(json['profit_percent']),
      defaultSellPrice: _parseDouble(json['default_sell_price']),
      sellPriceIncTax: _parseDouble(json['sell_price_inc_tax']),
      variationValueId: json['variation_value_id'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'sub_sku': subSku,
      'default_purchase_price': defaultPurchasePrice,
      'dpp_inc_tax': dppIncTax,
      'profit_percent': profitPercent,
      'default_sell_price': defaultSellPrice,
      'sell_price_inc_tax': sellPriceIncTax,
      'variation_value_id': variationValueId,
      'created_at': createdAt,
      'updated_at': updatedAt,
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











