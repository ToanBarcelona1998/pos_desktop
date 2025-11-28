//profit_loss_report_model.dart

class ProfitLossReportModel {
  String? totalPurchaseShippingCharge;
  String? totalSellShippingCharge;
  String? totalPurchaseAdditionalExpense;
  String? totalSellAdditionalExpense;
  String? totalTransferShippingCharges;
  String? openingStock;
  String? closingStock;
  String? totalPurchase;
  String? totalPurchaseDiscount;
  String? totalPurchaseReturn;
  String? totalSell;
  String? totalSellDiscount;
  String? totalSellReturn;
  String? totalSellRoundOff;
  int? totalExpense;
  String? totalAdjustment;
  String? totalRecovered;
  String? totalRewardAmount;
  double? netProfit;
  String? grossProfit;

  ProfitLossReportModel({
    this.totalPurchaseShippingCharge,
    this.totalSellShippingCharge,
    this.totalPurchaseAdditionalExpense,
    this.totalSellAdditionalExpense,
    this.totalTransferShippingCharges,
    this.openingStock,
    this.closingStock,
    this.totalPurchase,
    this.totalPurchaseDiscount,
    this.totalPurchaseReturn,
    this.totalSell,
    this.totalSellDiscount,
    this.totalSellReturn,
    this.totalSellRoundOff,
    this.totalExpense,
    this.totalAdjustment,
    this.totalRecovered,
    this.totalRewardAmount,
    this.netProfit,
    this.grossProfit,
  });

  ProfitLossReportModel.fromJson(Map<String, dynamic> json) {
    totalPurchaseShippingCharge = json['total_purchase_shipping_charge'].toString();
    totalSellShippingCharge = json['total_sell_shipping_charge'].toString();
    totalPurchaseAdditionalExpense = json['total_purchase_additional_expense'].toString();
    totalSellAdditionalExpense = json['total_sell_additional_expense'].toString();
    totalTransferShippingCharges = json['total_transfer_shipping_charges'].toString();
    openingStock = json['opening_stock'].toString();
    closingStock = json['closing_stock'].toString();
    totalPurchase = json['total_purchase'].toString();
    totalPurchaseDiscount = json['total_purchase_discount'].toString();
    totalPurchaseReturn = json['total_purchase_return'].toString();
    totalSell = json['total_sell'].toString();
    totalSellDiscount = json['total_sell_discount'].toString();
    totalSellReturn = json['total_sell_return'].toString();
    totalSellRoundOff = json['total_sell_round_off'].toString();
    totalExpense = json['total_expense'];
    totalAdjustment = json['total_adjustment'].toString();
    totalRecovered = json['total_recovered'].toString();
    totalRewardAmount = json['total_reward_amount'].toString();
    netProfit = json['net_profit'];
    grossProfit = json['gross_profit'].toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_purchase_shipping_charge'] = totalPurchaseShippingCharge;
    data['total_sell_shipping_charge'] = totalSellShippingCharge;
    data['total_purchase_additional_expense'] =
        totalPurchaseAdditionalExpense;
    data['total_transfer_shipping_charges'] = totalTransferShippingCharges;
    data['opening_stock'] = openingStock;
    data['closing_stock'] = closingStock;
    data['total_purchase'] = totalPurchase;
    data['total_purchase_discount'] = totalPurchaseDiscount;
    data['total_purchase_return'] = totalPurchaseReturn;
    data['total_sell'] = totalSell;
    data['total_sell_discount'] = totalSellDiscount;
    data['total_sell_return'] = totalSellReturn;
    data['total_sell_round_off'] = totalSellRoundOff;
    data['total_expense'] = totalExpense;
    data['total_adjustment'] = totalAdjustment;
    data['total_recovered'] = totalRecovered;
    data['total_reward_amount'] = totalRewardAmount;
    data['net_profit'] = netProfit;
    data['gross_profit'] = grossProfit;
    return data;
  }
}
