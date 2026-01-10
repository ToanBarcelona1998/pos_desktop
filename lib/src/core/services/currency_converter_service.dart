import 'package:domain/domain.dart';
import 'package:intl/intl.dart';

import '../../../app_config/di.dart';
import '../../../app_config/app_config.dart';
import '../../../helpers/other_helpers.dart';

/// Service để convert và format currency
class CurrencyConverterService {
  final ExchangeRateRepository _exchangeRateRepository;
  final double _defaultRate;

  CurrencyConverterService({
    ExchangeRateRepository? exchangeRateRepository,
    double? defaultRate,
  })  : _exchangeRateRepository =
            exchangeRateRepository ?? sl.get<ExchangeRateRepository>(),
        _defaultRate = defaultRate ??
            (sl.get<AppConfig>().defaultExchangeRate);

  /// Convert amount from VND to USD
  Future<double?> convertToUSD(double amountVND) async {
    final rateResult = await _exchangeRateRepository.getExchangeRate(
      baseCurrency: 'VND',
      targetCurrency: 'USD',
      defaultRate: _defaultRate,
    );

    return rateResult.fold(
      onSuccess: (rate) => amountVND / rate.conversionRate,
      onError: (_) {
        // Fallback to default rate
        return amountVND / _defaultRate;
      },
    );
  }

  /// Convert amount from USD to VND
  Future<double?> convertToVND(double amountUSD) async {
    final rateResult = await _exchangeRateRepository.getExchangeRate(
      baseCurrency: 'VND',
      targetCurrency: 'USD',
      defaultRate: _defaultRate,
    );

    return rateResult.fold(
      onSuccess: (rate) => amountUSD * rate.conversionRate,
      onError: (_) {
        // Fallback to default rate
        return amountUSD * _defaultRate;
      },
    );
  }

  /// Format currency with symbol
  String formatCurrency(
    double amount, {
    String currency = 'VND',
    int? decimals,
  }) {
    final symbol = _getCurrencySymbol(currency);

    // USD: 2 decimals, VND: 0 decimals
    final decimalPlaces = decimals ?? (currency.toUpperCase() == 'USD' ? 2 : 0);

    double convertAmount = double.tryParse(amount.toString()) ?? 0.0;
    var formatted = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalPlaces,
    ).format(convertAmount);

    return '$formatted $symbol';
  }

  String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'VND':
        return '₫';
      default:
        return currency;
    }
  }

  /// Get current exchange rate (cached or from API)
  Future<ExchangeRateEntity?> getCurrentRate() async {
    final result = await _exchangeRateRepository.getExchangeRate(
      defaultRate: _defaultRate,
    );

    return result.fold(
      onSuccess: (rate) => rate,
      onError: (_) => null,
    );
  }

  /// Format currency using Helper format (for backward compatibility)
  String formatCurrencyWithHelper(double amount, String currency) {
    final helper = Helper();
    final symbol = _getCurrencySymbol(currency);
    final formatted = helper.formatCurrency(amount);
    return '$formatted $symbol';
  }
}
