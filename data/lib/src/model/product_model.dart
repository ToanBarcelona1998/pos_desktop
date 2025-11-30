import 'base_model.dart';

/// DTO for product/variation data
class ProductModel extends BaseModel {
  final int? id;
  final int? productId;
  final int? variationId;
  final String? productName;
  final String? productVariationName;
  final String? variationName;
  final String? displayName;
  final String? sku;
  final String? subSku;
  final String? type;
  final int? enableStock;
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

  const ProductModel({
    this.id,
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

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Construct display_name if not present (like old code)
    String? displayName = json['display_name'] as String?;
    if (displayName == null || displayName.isEmpty) {
      final productName = json['product_name']?.toString() ?? '';
      final productVariationName = json['product_variation_name']?.toString() ?? '';
      final variationName = json['variation_name']?.toString() ?? '';
      displayName = '$productName $productVariationName $variationName'.trim();
    }

    // Use variation_id as id if id is not present (database uses variation_id as primary key)
    int? id = json['id'] as int?;
    if (id == null) {
      id = json['variation_id'] as int?;
    }

    return ProductModel(
      id: id,
      productId: json['product_id'] as int?,
      variationId: json['variation_id'] as int?,
      productName: json['product_name'] as String?,
      productVariationName: json['product_variation_name'] as String?,
      variationName: json['variation_name'] as String?,
      displayName: displayName,
      sku: json['sku'] as String?,
      subSku: json['sub_sku'] as String?,
      type: json['type'] as String?,
      enableStock: json['enable_stock'] as int?,
      brandId: json['brand_id'] as int?,
      unitId: json['unit_id'] as int?,
      categoryId: json['category_id'] as int?,
      subCategoryId: json['sub_category_id'] as int?,
      taxId: json['tax_id'] as int?,
      defaultSellPrice: _parseDouble(json['default_sell_price']),
      sellPriceIncTax: _parseDouble(json['sell_price_inc_tax']),
      productImageUrl: json['product_image_url'] as String?,
      productDescription: json['product_description'] as String?,
      qtyAvailable: _parseDouble(json['qty_available']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (variationId != null) 'variation_id': variationId,
      if (productName != null) 'product_name': productName,
      if (productVariationName != null)
        'product_variation_name': productVariationName,
      if (variationName != null) 'variation_name': variationName,
      if (displayName != null) 'display_name': displayName,
      if (sku != null) 'sku': sku,
      if (subSku != null) 'sub_sku': subSku,
      if (type != null) 'type': type,
      if (enableStock != null) 'enable_stock': enableStock,
      if (brandId != null) 'brand_id': brandId,
      if (unitId != null) 'unit_id': unitId,
      if (categoryId != null) 'category_id': categoryId,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (taxId != null) 'tax_id': taxId,
      if (defaultSellPrice != null) 'default_sell_price': defaultSellPrice,
      if (sellPriceIncTax != null) 'sell_price_inc_tax': sellPriceIncTax,
      if (productImageUrl != null) 'product_image_url': productImageUrl,
      if (productDescription != null) 'product_description': productDescription,
      if (qtyAvailable != null) 'qty_available': qtyAvailable,
    };
  }
}
