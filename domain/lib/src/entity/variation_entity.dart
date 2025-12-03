import '../core/entity.dart';

/// Product variation entity
class VariationEntity extends Entity {
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VariationEntity({
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

  @override
  List<Object?> get props => [
        id,
        productId,
        name,
        subSku,
        defaultPurchasePrice,
        dppIncTax,
        profitPercent,
        defaultSellPrice,
        sellPriceIncTax,
        variationValueId,
        createdAt,
        updatedAt,
      ];
}








