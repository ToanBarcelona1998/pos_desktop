import 'base_model.dart';

/// Business data model
class BusinessModel extends BaseModel {
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
  final int isActive;
  final String? createdAt;
  final String? updatedAt;

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
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as int,
      name: json['name'] as String,
      currencyId: json['currency_id']?.toString(),
      currencySymbol: json['currency_symbol'] as String?,
      currencyPrecision: json['currency_precision']?.toString(),
      logo: json['logo'] as String?,
      timeZone: json['time_zone'] as String?,
      fiscalYearStartMonth: json['fy_start_month']?.toString(),
      accountingMethod: json['accounting_method'] as String?,
      defaultSalesDiscount: json['default_sales_discount']?.toString(),
      sellPriceTax: json['sell_price_tax'] as String?,
      defaultProfitPercent: json['default_profit_percent']?.toString(),
      ownerId: json['owner_id'] as int?,
      isActive: json['is_active'] as int? ?? 1,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
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
    };
  }
}












