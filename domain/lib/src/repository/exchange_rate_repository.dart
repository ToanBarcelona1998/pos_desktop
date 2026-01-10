import '../core/result.dart';
import '../entity/exchange_rate_entity.dart';

abstract class ExchangeRateRepository {
  /// Get exchange rate with smart caching:
  /// - Check if updated today → return cache
  /// - If not updated today → fetch from API
  /// - If API fails → return cached (yesterday's value)
  /// - If no cache and API fails → return default value
  Future<Result<ExchangeRateEntity>> getExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
    double defaultRate = 25000.0,
  });

  /// Save exchange rate to cache
  Future<Result<void>> saveExchangeRate(ExchangeRateEntity rate);

  /// Get cached exchange rate
  Future<Result<ExchangeRateEntity?>> getCachedExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  });
}
