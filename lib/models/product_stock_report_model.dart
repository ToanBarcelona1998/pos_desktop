class ProductStockReportModel {
  String? totalSold;
  String? stockPrice;
  String? stock;
  String? product;
  String? sku;
  String? type;
  String? locationName;
  String? alertQuantity;
  String? categoryName;
  int? productId;
  String? unit;
  int? enableStock;
  String? unitPrice;

  ProductStockReportModel(
      {this.totalSold,
      this.stockPrice,
      this.stock,
      this.unit,
      this.categoryName,
      this.product,
      this.locationName,
      this.sku,
      this.type,
      this.alertQuantity,
      this.productId,
      this.enableStock,
      this.unitPrice});

  ProductStockReportModel.fromJson(Map<String, dynamic> json) {
    totalSold = json['total_sold'] ?? "....";
    stockPrice = json['stock_price'] ?? "....";
    stock = json['stock'] ?? "....";
    unit = json['unit'] ?? "....";
    product = json['product'] ?? "....";
    categoryName = json['category_name'] ?? "....";
    locationName = json['location_name'] ?? "....";
    sku = json['sku'] ?? "....";
    type = json['type'] ?? "....";
    alertQuantity = json['alert_quantity'] ?? "....";
    productId = json['product_id'] ?? "....";
    enableStock = json['enable_stock'] ?? "....";
    unitPrice = json['unit_price'] ?? "....";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_sold'] = totalSold;
    data['stock_price'] = stockPrice;
    data['stock'] = stock;
    data['unit'] = unit;
    data['product'] = product;
    data['category_name'] = categoryName;
    data['location_name'] = locationName;
    data['sku'] = sku;
    data['type'] = type;
    data['alert_quantity'] = alertQuantity;
    data['product_id'] = productId;
    data['enable_stock'] = enableStock;
    data['unit_price'] = unitPrice;
    return data;
  }
}
