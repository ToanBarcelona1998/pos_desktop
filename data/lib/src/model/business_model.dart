import 'base_model.dart';

/// Business data model
class BusinessModel extends BaseModel {
  final int id;
  final String name;
  final String? currencyId;
  final String? currencySymbol;
  final int? currencyPrecision;
  final String? logo;
  final String? timeZone;
  final String? fiscalYearStartMonth;
  final String? accountingMethod;
  final String? defaultSalesDiscount;
  final String? sellPriceTax;
  final String? defaultProfitPercent;
  final int? ownerId;
  final int isActive;
  final String? createdAt;
  final String? updatedAt;
  final int? quantityPrecision;
  final String? dateFormat;
  final String? timeFormat;
  final String? currencySymbolPlacement;
  final String? startDate;
  final String? taxNumber1;
  final String? taxLabel1;
  final String? taxNumber2;
  final String? taxLabel2;
  final String? defaultSalesTax;
  final String? skuPrefix;
  final int? enableProductExpiry;
  final String? expiryType;
  final String? onProductExpiry;
  final int? stopSellingBefore;
  final int? enableTooltip;
  final int? purchaseInDiffCurrency;
  final String? purchaseCurrencyId;
  final String? pExchangeRate;
  final int? transactionEditDays;
  final int? stockExpiryAlertDays;
  final int? enableBrand;
  final int? enableCategory;
  final int? enableSubCategory;
  final int? enablePriceTax;
  final int? enablePurchaseStatus;
  final int? enableLotNumber;
  final String? defaultUnit;
  final int? enableSubUnits;
  final int? enableRacks;
  final int? enableRow;
  final int? enablePosition;
  final int? enableEditingProductFromPurchase;
  final String? salesCmsnAgnt;
  final int? itemAdditionMethod;
  final int? enableInlineTax;
  final List<String>? enabledModules;
  final Map<String, dynamic>? refNoPrefixes;
  final String? themeColor;
  final int? createdBy;
  final int? enableRp;
  final String? rpName;
  final String? amountForUnitRp;
  final String? minOrderTotalForRp;
  final String? maxRpPerOrder;
  final String? redeemAmountPerUnitRp;
  final String? minOrderTotalForRedeem;
  final String? minRedeemPoint;
  final String? maxRedeemPoint;
  final String? rpExpiryPeriod;
  final String? rpExpiryType;

  const BusinessModel({
    required this.id,
    required this.name,
    this.currencyId,
    this.currencySymbol,
    this.currencyPrecision,
    this.logo,
    this.timeZone,
    this.fiscalYearStartMonth,
    this.accountingMethod,
    this.defaultSalesDiscount,
    this.sellPriceTax,
    this.defaultProfitPercent,
    this.ownerId,
    this.isActive = 1,
    this.createdAt,
    this.updatedAt,
    this.quantityPrecision,
    this.dateFormat,
    this.timeFormat,
    this.currencySymbolPlacement,
    this.startDate,
    this.taxNumber1,
    this.taxLabel1,
    this.taxNumber2,
    this.taxLabel2,
    this.defaultSalesTax,
    this.skuPrefix,
    this.enableProductExpiry,
    this.expiryType,
    this.onProductExpiry,
    this.stopSellingBefore,
    this.enableTooltip,
    this.purchaseInDiffCurrency,
    this.purchaseCurrencyId,
    this.pExchangeRate,
    this.transactionEditDays,
    this.stockExpiryAlertDays,
    this.enableBrand,
    this.enableCategory,
    this.enableSubCategory,
    this.enablePriceTax,
    this.enablePurchaseStatus,
    this.enableLotNumber,
    this.defaultUnit,
    this.enableSubUnits,
    this.enableRacks,
    this.enableRow,
    this.enablePosition,
    this.enableEditingProductFromPurchase,
    this.salesCmsnAgnt,
    this.itemAdditionMethod,
    this.enableInlineTax,
    this.enabledModules,
    this.refNoPrefixes,
    this.themeColor,
    this.createdBy,
    this.enableRp,
    this.rpName,
    this.amountForUnitRp,
    this.minOrderTotalForRp,
    this.maxRpPerOrder,
    this.redeemAmountPerUnitRp,
    this.minOrderTotalForRedeem,
    this.minRedeemPoint,
    this.maxRedeemPoint,
    this.rpExpiryPeriod,
    this.rpExpiryType,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    // Extract currency symbol from nested currency object if available
    String? currencySymbol;
    if (json['currency'] != null && json['currency'] is Map) {
      currencySymbol = json['currency']['symbol'] as String?;
    } else {
      currencySymbol = json['currency_symbol'] as String?;
    }

    // Extract currency_precision - can be int or in currency object
    int? currencyPrecision;
    if (json['currency_precision'] != null) {
      currencyPrecision = json['currency_precision'] is int
          ? json['currency_precision'] as int
          : int.tryParse(json['currency_precision'].toString());
    }

    // Parse enabled_modules array
    List<String>? enabledModules;
    if (json['enabled_modules'] != null && json['enabled_modules'] is List) {
      enabledModules = (json['enabled_modules'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Parse ref_no_prefixes object
    Map<String, dynamic>? refNoPrefixes;
    if (json['ref_no_prefixes'] != null && json['ref_no_prefixes'] is Map) {
      refNoPrefixes = Map<String, dynamic>.from(json['ref_no_prefixes']);
    }

    return BusinessModel(
      id: int.parse(json['id'].toString()),
      name: json['name'] as String,
      currencyId: json['currency_id']?.toString(),
      currencySymbol: currencySymbol,
      currencyPrecision: currencyPrecision,
      logo: json['logo'] as String?,
      timeZone: json['time_zone'] as String?,
      fiscalYearStartMonth: json['fy_start_month']?.toString(),
      accountingMethod: json['accounting_method'] as String?,
      defaultSalesDiscount: json['default_sales_discount']?.toString(),
      sellPriceTax: json['sell_price_tax'] as String?,
      defaultProfitPercent: json['default_profit_percent']?.toString(),
      ownerId: int.tryParse(json['owner_id']?.toString() ?? ''),
      isActive: int.tryParse(json['is_active']?.toString() ?? '') ?? 1,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      quantityPrecision: int.tryParse(json['quantity_precision']?.toString() ?? ''),
      dateFormat: json['date_format'] as String?,
      timeFormat: json['time_format'] as String?,
      currencySymbolPlacement: json['currency_symbol_placement'] as String?,
      startDate: json['start_date'] as String?,
      taxNumber1: json['tax_number_1'] as String?,
      taxLabel1: json['tax_label_1'] as String?,
      taxNumber2: json['tax_number_2'] as String?,
      taxLabel2: json['tax_label_2'] as String?,
      defaultSalesTax: json['default_sales_tax']?.toString(),
      skuPrefix: json['sku_prefix'] as String?,
      enableProductExpiry: int.tryParse(json['enable_product_expiry']?.toString() ?? ''),
      expiryType: json['expiry_type'] as String?,
      onProductExpiry: json['on_product_expiry'] as String?,
      stopSellingBefore: int.tryParse(json['stop_selling_before']?.toString() ?? ''),
      enableTooltip: int.tryParse(json['enable_tooltip']?.toString() ?? ''),
      purchaseInDiffCurrency: int.tryParse(json['purchase_in_diff_currency']?.toString() ?? ''),
      purchaseCurrencyId: json['purchase_currency_id']?.toString(),
      pExchangeRate: json['p_exchange_rate']?.toString(),
      transactionEditDays: int.tryParse(json['transaction_edit_days']?.toString() ?? ''),
      stockExpiryAlertDays: int.tryParse(json['stock_expiry_alert_days']?.toString() ?? ''),
      enableBrand: int.tryParse(json['enable_brand']?.toString() ?? ''),
      enableCategory: int.tryParse(json['enable_category']?.toString() ?? ''),
      enableSubCategory: int.tryParse(json['enable_sub_category']?.toString() ?? ''),
      enablePriceTax: int.tryParse(json['enable_price_tax']?.toString() ?? ''),
      enablePurchaseStatus: int.tryParse(json['enable_purchase_status']?.toString() ?? ''),
      enableLotNumber: int.tryParse(json['enable_lot_number']?.toString() ?? ''),
      defaultUnit: json['default_unit'] as String?,
      enableSubUnits: int.tryParse(json['enable_sub_units']?.toString() ?? ''),
      enableRacks: int.tryParse(json['enable_racks']?.toString() ?? ''),
      enableRow: int.tryParse(json['enable_row']?.toString() ?? ''),
      enablePosition: int.tryParse(json['enable_position']?.toString() ?? ''),
      enableEditingProductFromPurchase: int.tryParse(json['enable_editing_product_from_purchase']?.toString() ?? ''),
      salesCmsnAgnt: json['sales_cmsn_agnt']?.toString(),
      itemAdditionMethod: int.tryParse(json['item_addition_method']?.toString() ?? ''),
      enableInlineTax: int.tryParse(json['enable_inline_tax']?.toString() ?? ''),
      enabledModules: enabledModules,
      refNoPrefixes: refNoPrefixes,
      themeColor: json['theme_color'] as String?,
      createdBy: int.tryParse(json['created_by']?.toString() ?? ''),
      enableRp: int.tryParse(json['enable_rp']?.toString() ?? ''),
      rpName: json['rp_name'] as String?,
      amountForUnitRp: json['amount_for_unit_rp']?.toString(),
      minOrderTotalForRp: json['min_order_total_for_rp']?.toString(),
      maxRpPerOrder: json['max_rp_per_order']?.toString(),
      redeemAmountPerUnitRp: json['redeem_amount_per_unit_rp']?.toString(),
      minOrderTotalForRedeem: json['min_order_total_for_redeem']?.toString(),
      minRedeemPoint: json['min_redeem_point']?.toString(),
      maxRedeemPoint: json['max_redeem_point']?.toString(),
      rpExpiryPeriod: json['rp_expiry_period']?.toString(),
      rpExpiryType: json['rp_expiry_type'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'currency_id': currencyId,
      'currency_symbol': currencySymbol,
      'currency_precision': currencyPrecision,
      'logo': logo,
      'time_zone': timeZone,
      'fy_start_month': fiscalYearStartMonth,
      'accounting_method': accountingMethod,
      'default_sales_discount': defaultSalesDiscount,
      'sell_price_tax': sellPriceTax,
      'default_profit_percent': defaultProfitPercent,
      'owner_id': ownerId,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'quantity_precision': quantityPrecision,
      'date_format': dateFormat,
      'time_format': timeFormat,
      'currency_symbol_placement': currencySymbolPlacement,
      'start_date': startDate,
      'tax_number_1': taxNumber1,
      'tax_label_1': taxLabel1,
      'tax_number_2': taxNumber2,
      'tax_label_2': taxLabel2,
      'default_sales_tax': defaultSalesTax,
      'sku_prefix': skuPrefix,
      'enable_product_expiry': enableProductExpiry,
      'expiry_type': expiryType,
      'on_product_expiry': onProductExpiry,
      'stop_selling_before': stopSellingBefore,
      'enable_tooltip': enableTooltip,
      'purchase_in_diff_currency': purchaseInDiffCurrency,
      'purchase_currency_id': purchaseCurrencyId,
      'p_exchange_rate': pExchangeRate,
      'transaction_edit_days': transactionEditDays,
      'stock_expiry_alert_days': stockExpiryAlertDays,
      'enable_brand': enableBrand,
      'enable_category': enableCategory,
      'enable_sub_category': enableSubCategory,
      'enable_price_tax': enablePriceTax,
      'enable_purchase_status': enablePurchaseStatus,
      'enable_lot_number': enableLotNumber,
      'default_unit': defaultUnit,
      'enable_sub_units': enableSubUnits,
      'enable_racks': enableRacks,
      'enable_row': enableRow,
      'enable_position': enablePosition,
      'enable_editing_product_from_purchase': enableEditingProductFromPurchase,
      'sales_cmsn_agnt': salesCmsnAgnt,
      'item_addition_method': itemAdditionMethod,
      'enable_inline_tax': enableInlineTax,
      'enabled_modules': enabledModules,
      'ref_no_prefixes': refNoPrefixes,
      'theme_color': themeColor,
      'created_by': createdBy,
      'enable_rp': enableRp,
      'rp_name': rpName,
      'amount_for_unit_rp': amountForUnitRp,
      'min_order_total_for_rp': minOrderTotalForRp,
      'max_rp_per_order': maxRpPerOrder,
      'redeem_amount_per_unit_rp': redeemAmountPerUnitRp,
      'min_order_total_for_redeem': minOrderTotalForRedeem,
      'min_redeem_point': minRedeemPoint,
      'max_redeem_point': maxRedeemPoint,
      'rp_expiry_period': rpExpiryPeriod,
      'rp_expiry_type': rpExpiryType,
    };
  }
}












