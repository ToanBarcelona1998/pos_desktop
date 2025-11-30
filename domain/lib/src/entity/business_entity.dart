import '../core/entity.dart';

/// Business entity representing business details
class BusinessEntity extends Entity {
  final int id;
  final String name;
  final String? currencyId;
  final String? currencySymbol;
  final String? currencyPrecision;
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
      ];
}





