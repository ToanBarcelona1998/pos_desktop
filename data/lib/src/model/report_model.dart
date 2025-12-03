import 'base_model.dart';

/// Profit loss report data model
class ProfitLossReportModel extends BaseModel {
  final double openingStock;
  final double closingStock;
  final double totalPurchase;
  final double totalTransferShippingCharges;
  final double totalSell;
  final double totalSellDiscount;
  final double totalRecoveredDiscount;
  final double totalRewardAmount;
  final double totalSellRoundOff;
  final double totalSellReturn;
  final double totalExpense;
  final double totalAdjustment;
  final double totalPurchaseShippingCharge;
  final double totalSellShippingCharge;
  final double totalPurchaseReturn;
  final double grossProfit;
  final double netProfit;

  const ProfitLossReportModel({
    required this.openingStock,
    required this.closingStock,
    required this.totalPurchase,
    required this.totalTransferShippingCharges,
    required this.totalSell,
    required this.totalSellDiscount,
    required this.totalRecoveredDiscount,
    required this.totalRewardAmount,
    required this.totalSellRoundOff,
    required this.totalSellReturn,
    required this.totalExpense,
    required this.totalAdjustment,
    required this.totalPurchaseShippingCharge,
    required this.totalSellShippingCharge,
    required this.totalPurchaseReturn,
    required this.grossProfit,
    required this.netProfit,
  });

  factory ProfitLossReportModel.fromJson(Map<String, dynamic> json) {
    return ProfitLossReportModel(
      openingStock: _parseDouble(json['opening_stock']),
      closingStock: _parseDouble(json['closing_stock']),
      totalPurchase: _parseDouble(json['total_purchase']),
      totalTransferShippingCharges: _parseDouble(json['total_transfer_shipping_charges']),
      totalSell: _parseDouble(json['total_sell']),
      totalSellDiscount: _parseDouble(json['total_sell_discount']),
      totalRecoveredDiscount: _parseDouble(json['total_recovered_discount']),
      totalRewardAmount: _parseDouble(json['total_reward_amount']),
      totalSellRoundOff: _parseDouble(json['total_sell_round_off']),
      totalSellReturn: _parseDouble(json['total_sell_return']),
      totalExpense: _parseDouble(json['total_expense']),
      totalAdjustment: _parseDouble(json['total_adjustment']),
      totalPurchaseShippingCharge: _parseDouble(json['total_purchase_shipping_charge']),
      totalSellShippingCharge: _parseDouble(json['total_sell_shipping_charge']),
      totalPurchaseReturn: _parseDouble(json['total_purchase_return']),
      grossProfit: _parseDouble(json['gross_profit']),
      netProfit: _parseDouble(json['net_profit']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'opening_stock': openingStock,
      'closing_stock': closingStock,
      'total_purchase': totalPurchase,
      'total_transfer_shipping_charges': totalTransferShippingCharges,
      'total_sell': totalSell,
      'total_sell_discount': totalSellDiscount,
      'total_recovered_discount': totalRecoveredDiscount,
      'total_reward_amount': totalRewardAmount,
      'total_sell_round_off': totalSellRoundOff,
      'total_sell_return': totalSellReturn,
      'total_expense': totalExpense,
      'total_adjustment': totalAdjustment,
      'total_purchase_shipping_charge': totalPurchaseShippingCharge,
      'total_sell_shipping_charge': totalSellShippingCharge,
      'total_purchase_return': totalPurchaseReturn,
      'gross_profit': grossProfit,
      'net_profit': netProfit,
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

/// Product stock report data model
class ProductStockReportModel extends BaseModel {
  final int productId;
  final String productName;
  final String? sku;
  final double totalSold;
  final double totalTransferred;
  final double totalAdjusted;
  final double currentStock;
  final double unitPrice;
  final double stockValue;

  const ProductStockReportModel({
    required this.productId,
    required this.productName,
    this.sku,
    required this.totalSold,
    required this.totalTransferred,
    required this.totalAdjusted,
    required this.currentStock,
    required this.unitPrice,
    required this.stockValue,
  });

  factory ProductStockReportModel.fromJson(Map<String, dynamic> json) {
    return ProductStockReportModel(
      productId: json['product_id'] as int? ?? json['id'] as int? ?? 0,
      productName: json['product'] as String? ?? json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      totalSold: _parseDouble(json['total_sold']),
      totalTransferred: _parseDouble(json['total_transferred']),
      totalAdjusted: _parseDouble(json['total_adjusted']),
      currentStock: _parseDouble(json['stock'] ?? json['current_stock']),
      unitPrice: _parseDouble(json['unit_price']),
      stockValue: _parseDouble(json['stock_price'] ?? json['stock_value']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product': productName,
      'sku': sku,
      'total_sold': totalSold,
      'total_transferred': totalTransferred,
      'total_adjusted': totalAdjusted,
      'stock': currentStock,
      'unit_price': unitPrice,
      'stock_price': stockValue,
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








