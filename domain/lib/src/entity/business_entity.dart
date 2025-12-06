import '../core/entity.dart';

/// Business entity representing business details
class BusinessEntity extends Entity {
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
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
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
  final bool enableProductExpiry;
  final String? expiryType;
  final String? onProductExpiry;
  final int? stopSellingBefore;
  final bool enableTooltip;
  final bool purchaseInDiffCurrency;
  final String? purchaseCurrencyId;
  final String? pExchangeRate;
  final int? transactionEditDays;
  final int? stockExpiryAlertDays;
  final bool enableBrand;
  final bool enableCategory;
  final bool enableSubCategory;
  final bool enablePriceTax;
  final bool enablePurchaseStatus;
  final bool enableLotNumber;
  final String? defaultUnit;
  final bool enableSubUnits;
  final bool enableRacks;
  final bool enableRow;
  final bool enablePosition;
  final bool enableEditingProductFromPurchase;
  final String? salesCmsnAgnt;
  final int? itemAdditionMethod;
  final bool enableInlineTax;
  final List<String>? enabledModules;
  final Map<String, dynamic>? refNoPrefixes;
  final String? themeColor;
  final int? createdBy;
  final bool enableRp;
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

  const BusinessEntity({
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
    this.isActive = true,
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
    this.enableProductExpiry = false,
    this.expiryType,
    this.onProductExpiry,
    this.stopSellingBefore,
    this.enableTooltip = false,
    this.purchaseInDiffCurrency = false,
    this.purchaseCurrencyId,
    this.pExchangeRate,
    this.transactionEditDays,
    this.stockExpiryAlertDays,
    this.enableBrand = false,
    this.enableCategory = false,
    this.enableSubCategory = false,
    this.enablePriceTax = false,
    this.enablePurchaseStatus = false,
    this.enableLotNumber = false,
    this.defaultUnit,
    this.enableSubUnits = false,
    this.enableRacks = false,
    this.enableRow = false,
    this.enablePosition = false,
    this.enableEditingProductFromPurchase = false,
    this.salesCmsnAgnt,
    this.itemAdditionMethod,
    this.enableInlineTax = false,
    this.enabledModules,
    this.refNoPrefixes,
    this.themeColor,
    this.createdBy,
    this.enableRp = false,
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

  @override
  List<Object?> get props => [
        id,
        name,
        currencyId,
        currencySymbol,
        currencyPrecision,
        logo,
        timeZone,
        fiscalYearStartMonth,
        accountingMethod,
        defaultSalesDiscount,
        sellPriceTax,
        defaultProfitPercent,
        ownerId,
        isActive,
        createdAt,
        updatedAt,
        quantityPrecision,
        dateFormat,
        timeFormat,
        currencySymbolPlacement,
        startDate,
        taxNumber1,
        taxLabel1,
        taxNumber2,
        taxLabel2,
        defaultSalesTax,
        skuPrefix,
        enableProductExpiry,
        expiryType,
        onProductExpiry,
        stopSellingBefore,
        enableTooltip,
        purchaseInDiffCurrency,
        purchaseCurrencyId,
        pExchangeRate,
        transactionEditDays,
        stockExpiryAlertDays,
        enableBrand,
        enableCategory,
        enableSubCategory,
        enablePriceTax,
        enablePurchaseStatus,
        enableLotNumber,
        defaultUnit,
        enableSubUnits,
        enableRacks,
        enableRow,
        enablePosition,
        enableEditingProductFromPurchase,
        salesCmsnAgnt,
        itemAdditionMethod,
        enableInlineTax,
        enabledModules,
        refNoPrefixes,
        themeColor,
        createdBy,
        enableRp,
        rpName,
        amountForUnitRp,
        minOrderTotalForRp,
        maxRpPerOrder,
        redeemAmountPerUnitRp,
        minOrderTotalForRedeem,
        minRedeemPoint,
        maxRedeemPoint,
        rpExpiryPeriod,
        rpExpiryType,
      ];
}












