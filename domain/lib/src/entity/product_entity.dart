import '../core/entity.dart';

final class ProductEntity extends Entity {
  final int id;
  final int? productId;
  final int? variationId;
  final String? productName;
  final String? productVariationName;
  final String? variationName;
  final String? displayName;
  final String? sku;
  final String? subSku;
  final String? type;
  final bool? enableStock;
  final int? brandId;
  final int? unitId;
  final int? categoryId;
  final int? subCategoryId;
  final int? taxId;
  final double? defaultSellPrice;
  final double? sellPriceIncTax;
  final String? productImageUrl;
  final String? productDescription;
  final double? qtyAvailable;

  const ProductEntity({
    required this.id,
    this.productId,
    this.variationId,
    this.productName,
    this.productVariationName,
    this.variationName,
    this.displayName,
    this.sku,
    this.subSku,
    this.type,
    this.enableStock,
    this.brandId,
    this.unitId,
    this.categoryId,
    this.subCategoryId,
    this.taxId,
    this.defaultSellPrice,
    this.sellPriceIncTax,
    this.productImageUrl,
    this.productDescription,
    this.qtyAvailable,
  });

  @override
  List<Object?> get props => [
        id,
        productId,
        variationId,
        displayName,
        sku,
      ];

  ProductEntity copyWith({
    int? id,
    int? productId,
    int? variationId,
    String? productName,
    String? productVariationName,
    String? variationName,
    String? displayName,
    String? sku,
    String? subSku,
    String? type,
    bool? enableStock,
    int? brandId,
    int? unitId,
    int? categoryId,
    int? subCategoryId,
    int? taxId,
    double? defaultSellPrice,
    double? sellPriceIncTax,
    String? productImageUrl,
    String? productDescription,
    double? qtyAvailable,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      variationId: variationId ?? this.variationId,
      productName: productName ?? this.productName,
      productVariationName: productVariationName ?? this.productVariationName,
      variationName: variationName ?? this.variationName,
      displayName: displayName ?? this.displayName,
      sku: sku ?? this.sku,
      subSku: subSku ?? this.subSku,
      type: type ?? this.type,
      enableStock: enableStock ?? this.enableStock,
      brandId: brandId ?? this.brandId,
      unitId: unitId ?? this.unitId,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      taxId: taxId ?? this.taxId,
      defaultSellPrice: defaultSellPrice ?? this.defaultSellPrice,
      sellPriceIncTax: sellPriceIncTax ?? this.sellPriceIncTax,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      productDescription: productDescription ?? this.productDescription,
      qtyAvailable: qtyAvailable ?? this.qtyAvailable,
    );
  }
}





