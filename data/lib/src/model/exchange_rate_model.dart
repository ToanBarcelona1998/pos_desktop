import 'dart:convert';

import 'base_model.dart';

class ExchangeRateModel extends BaseModel {
  final String baseCurrency;
  final String targetCurrency;
  final double conversionRate;
  final DateTime lastUpdateDate;
  final DateTime? nextUpdateDate;
  final String source;
  final bool isFromCache;

  ExchangeRateModel({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.conversionRate,
    required this.lastUpdateDate,
    this.nextUpdateDate,
    this.source = 'api',
    this.isFromCache = false,
  });

  /// Parse từ ExchangeRate-API.com response
  factory ExchangeRateModel.fromApiJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      baseCurrency: json['base_code'] as String? ?? 'VND',
      targetCurrency: json['target_code'] as String? ?? 'USD',
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
      lastUpdateDate: json['time_last_update_unix'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['time_last_update_unix'] as int) * 1000)
          : DateTime.now(),
      nextUpdateDate: json['time_next_update_unix'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['time_next_update_unix'] as int) * 1000)
          : null,
      source: 'api',
      isFromCache: false,
    );
  }

  /// Parse từ cached data (SharedPreferences)
  factory ExchangeRateModel.fromCacheJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      baseCurrency: json['base_currency'] as String? ?? 'VND',
      targetCurrency: json['target_currency'] as String? ?? 'USD',
      conversionRate: (json['conversion_rate'] as num?)?.toDouble() ?? 0.0,
      lastUpdateDate: json['last_update_date'] != null
          ? DateTime.parse(json['last_update_date'] as String)
          : DateTime.now(),
      nextUpdateDate: json['next_update_date'] != null
          ? DateTime.parse(json['next_update_date'] as String)
          : null,
      source: json['source'] as String? ?? 'cache',
      isFromCache: true,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'base_currency': baseCurrency,
      'target_currency': targetCurrency,
      'conversion_rate': conversionRate,
      'last_update_date': lastUpdateDate.toIso8601String(),
      'next_update_date': nextUpdateDate?.toIso8601String(),
      'source': source,
    };
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'base_currency': baseCurrency,
      'target_currency': targetCurrency,
      'conversion_rate': conversionRate,
      'last_update_date': lastUpdateDate.toIso8601String(),
      'next_update_date': nextUpdateDate?.toIso8601String(),
      'source': source,
      'is_from_cache': isFromCache,
    };
  }
}
