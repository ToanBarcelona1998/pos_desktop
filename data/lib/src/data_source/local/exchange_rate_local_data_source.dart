import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../model/exchange_rate_model.dart';

abstract class ExchangeRateLocalDataSource {
  /// Get cached exchange rate
  /// Key format: exchange_rate_{baseCurrency}_{targetCurrency}
  Future<ExchangeRateModel?> getCachedExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  });

  /// Save exchange rate to cache
  Future<void> saveExchangeRate(ExchangeRateModel rate);

  /// Get last update date for a currency pair
  Future<DateTime?> getLastUpdateDate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  });

  /// Check if rate was updated today
  Future<bool> wasUpdatedToday({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  });

  /// Clear all cached exchange rates
  Future<void> clearCache();
}

class ExchangeRateLocalDataSourceImpl
    implements ExchangeRateLocalDataSource {
  static const String _keyPrefix = 'exchange_rate_';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Generate cache key: exchange_rate_vnd_usd
  String _getCacheKey(String base, String target) {
    return '$_keyPrefix${base.toLowerCase()}_${target.toLowerCase()}';
  }

  @override
  Future<ExchangeRateModel?> getCachedExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  }) async {
    final prefs = await _prefs;
    final key = _getCacheKey(baseCurrency, targetCurrency);
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ExchangeRateModel.fromCacheJson(json);
    } catch (e) {
      // If parsing fails, return null (cache corrupted)
      return null;
    }
  }

  @override
  Future<void> saveExchangeRate(ExchangeRateModel rate) async {
    final prefs = await _prefs;
    final key = _getCacheKey(rate.baseCurrency, rate.targetCurrency);
    final jsonString = jsonEncode(rate.toCacheJson());
    await prefs.setString(key, jsonString);
  }

  @override
  Future<DateTime?> getLastUpdateDate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  }) async {
    final prefs = await _prefs;
    final key = _getCacheKey(baseCurrency, targetCurrency);
    final jsonString = prefs.getString(key);

    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final lastUpdateStr = json['last_update_date'] as String?;
      if (lastUpdateStr != null) {
        return DateTime.parse(lastUpdateStr);
      }
    } catch (_) {
      // Ignore parse errors
    }

    return null;
  }

  @override
  Future<bool> wasUpdatedToday({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  }) async {
    final lastUpdate = await getLastUpdateDate(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
    );

    if (lastUpdate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastUpdateDay = DateTime(
      lastUpdate.year,
      lastUpdate.month,
      lastUpdate.day,
    );

    return today.isAtSameMomentAs(lastUpdateDay);
  }

  @override
  Future<void> clearCache() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys()
        .where((k) => k.startsWith(_keyPrefix))
        .toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
