import '../core/entity.dart';

/// Profit loss report entity
class ProfitLossReportEntity extends Entity {
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

  const ProfitLossReportEntity({
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

  @override
  List<Object?> get props => [
        openingStock,
        closingStock,
        totalPurchase,
        totalTransferShippingCharges,
        totalSell,
        totalSellDiscount,
        totalRecoveredDiscount,
        totalRewardAmount,
        totalSellRoundOff,
        totalSellReturn,
        totalExpense,
        totalAdjustment,
        totalPurchaseShippingCharge,
        totalSellShippingCharge,
        totalPurchaseReturn,
        grossProfit,
        netProfit,
      ];
}

/// Product stock report entity
class ProductStockReportEntity extends Entity {
  final int productId;
  final String productName;
  final String? sku;
  final double totalSold;
  final double totalTransferred;
  final double totalAdjusted;
  final double currentStock;
  final double unitPrice;
  final double stockValue;

  const ProductStockReportEntity({
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

  @override
  List<Object?> get props => [
        productId,
        productName,
        sku,
        totalSold,
        totalTransferred,
        totalAdjusted,
        currentStock,
        unitPrice,
        stockValue,
      ];
}












