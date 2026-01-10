import '../core/entity.dart';

/// Exchange rate entity representing currency exchange rate
class ExchangeRateEntity extends Entity {
  final String baseCurrency;      // "VND"
  final String targetCurrency;    // "USD"
  final double conversionRate;    // Tỉ giá: 1 USD = ? VND
  final DateTime lastUpdateDate;  // Ngày update cuối cùng
  final DateTime? nextUpdateDate; // Ngày update tiếp theo (từ API)
  final String source;            // "api", "cache", "default"
  final bool isFromCache;         // Có phải từ cache không

  const ExchangeRateEntity({
    required this.baseCurrency,
    required this.targetCurrency,
    required this.conversionRate,
    required this.lastUpdateDate,
    this.nextUpdateDate,
    this.source = 'api',
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [
        baseCurrency,
        targetCurrency,
        conversionRate,
        lastUpdateDate,
        nextUpdateDate,
        source,
        isFromCache,
      ];

  /// Check if rate needs update (đã quá 1 ngày)
  bool needsUpdate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastUpdate = DateTime(
      lastUpdateDate.year,
      lastUpdateDate.month,
      lastUpdateDate.day,
    );
    return today.isAfter(lastUpdate);
  }

  /// Check if rate is stale (quá 2 ngày, cần fallback)
  bool isStale() {
    final now = DateTime.now();
    final lastUpdate = DateTime(
      lastUpdateDate.year,
      lastUpdateDate.month,
      lastUpdateDate.day,
    );
    final daysDiff = now.difference(lastUpdate).inDays;
    return daysDiff >= 2;
  }

  ExchangeRateEntity copyWith({
    String? baseCurrency,
    String? targetCurrency,
    double? conversionRate,
    DateTime? lastUpdateDate,
    DateTime? nextUpdateDate,
    String? source,
    bool? isFromCache,
  }) {
    return ExchangeRateEntity(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      conversionRate: conversionRate ?? this.conversionRate,
      lastUpdateDate: lastUpdateDate ?? this.lastUpdateDate,
      nextUpdateDate: nextUpdateDate ?? this.nextUpdateDate,
      source: source ?? this.source,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}
