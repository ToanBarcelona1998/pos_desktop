# Exchange Rate & Multi-Currency Invoice Implementation Plan

## 📋 Tổng Quan

Plan này implement exchange rate system sử dụng ExchangeRate-API.com và multi-currency invoice printing với 2 options: VND và USD.

**Key Requirements:**
- Cache exchange rate theo key nhất định
- Mỗi ngày chỉ load tối đa 1 lần từ API
- Nếu API lỗi → sử dụng cached value của ngày trước
- Nếu lần đầu load lỗi → sử dụng default value từ config
- Support in hóa đơn bằng VND hoặc USD với currency conversion

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│      ExchangeRate-API.com (External)    │
│      GET /v6/{API_KEY}/pair/VND/USD     │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│    ExchangeRateRemoteDataSource         │
│    - Fetch từ API                       │
│    - Handle errors                      │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│    ExchangeRateRepository               │
│    - Validate daily update              │
│    - Fallback logic                     │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│    ExchangeRateLocalDataSource          │
│    - Cache trong SharedPreferences      │
│    - Key: exchange_rate_vnd_usd         │
│    - Store: rate, last_update_date      │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│    CurrencyConverterService             │
│    - Convert VND ↔ USD                  │
│    - Format với symbol                  │
└───────────────┬─────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────┐
│    Print Invoice Flow                   │
│    - Currency Selection Dialog          │
│    - Print với currency conversion      │
└─────────────────────────────────────────┘
```

---

## 📦 Step 1: API Configuration

### 1.1 Thêm API Key vào Config

**File:** `lib/app_config/env_config.dart`

```dart
class EnvConfig {
  // ... existing fields ...
  
  final String exchangeRateApiKey;
  final double defaultExchangeRate;  // Default rate nếu API fail lần đầu
  
  EnvConfig({
    // ... existing parameters ...
    required this.exchangeRateApiKey,
    this.defaultExchangeRate = 25000.0,  // Default: 1 USD = 25000 VND
  });
  
  factory EnvConfig.fromJson(Map<String, dynamic> json) {
    return EnvConfig(
      // ... existing fields ...
      exchangeRateApiKey: json['exchange_rate_api_key'] ?? '',
      defaultExchangeRate: (json['default_exchange_rate'] ?? 25000.0).toDouble(),
    );
  }
}
```

**File:** `.env.development` hoặc `.env.production`

```env
EXCHANGE_RATE_API_KEY=your_api_key_here
DEFAULT_EXCHANGE_RATE=25000.0
```

---

## 📦 Step 2: Exchange Rate Entity & Model

### 2.1 Entity

**File:** `domain/lib/src/entity/exchange_rate_entity.dart`

```dart
class ExchangeRateEntity {
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
}
```

### 2.2 Model

**File:** `data/lib/src/model/exchange_rate_model.dart`

```dart
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
      baseCurrency: json['base_code'] ?? 'VND',
      targetCurrency: json['target_code'] ?? 'USD',
      conversionRate: (json['conversion_rate'] ?? 0.0).toDouble(),
      lastUpdateDate: json['time_last_update_unix'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['time_last_update_unix'] * 1000)
          : DateTime.now(),
      nextUpdateDate: json['time_next_update_unix'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['time_next_update_unix'] * 1000)
          : null,
      source: 'api',
      isFromCache: false,
    );
  }

  /// Parse từ cached data (SharedPreferences)
  factory ExchangeRateModel.fromCacheJson(Map<String, dynamic> json) {
    return ExchangeRateModel(
      baseCurrency: json['base_currency'] ?? 'VND',
      targetCurrency: json['target_currency'] ?? 'USD',
      conversionRate: (json['conversion_rate'] ?? 0.0).toDouble(),
      lastUpdateDate: json['last_update_date'] != null
          ? DateTime.parse(json['last_update_date'])
          : DateTime.now(),
      nextUpdateDate: json['next_update_date'] != null
          ? DateTime.parse(json['next_update_date'])
          : null,
      source: json['source'] ?? 'cache',
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
```

---

## 📦 Step 3: Exchange Rate Remote Data Source

**File:** `data/lib/src/data_source/remote/exchange_rate_remote_data_source.dart`

```dart
import 'package:dio/dio.dart';
import 'package:domain/domain.dart';

import '../../model/exchange_rate_model.dart';

abstract class ExchangeRateRemoteDataSource {
  Future<Either<Failure, ExchangeRateModel>> getExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
    required String apiKey,
  });
}

class ExchangeRateRemoteDataSourceImpl
    implements ExchangeRateRemoteDataSource {
  final Dio dio;

  ExchangeRateRemoteDataSourceImpl({required this.dio});

  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  @override
  Future<Either<Failure, ExchangeRateModel>> getExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
    required String apiKey,
  }) async {
    try {
      final url = '$_baseUrl/$apiKey/pair/$baseCurrency/$targetCurrency';

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Check for API errors
        if (data['result'] == 'error') {
          final errorType = data['error-type'] as String?;
          return Left(_handleApiError(errorType));
        }

        // Success response
        if (data['result'] == 'success') {
          final model = ExchangeRateModel.fromApiJson(data);
          return Right(model);
        }

        return Left(UnknownFailure(
          message: 'Unexpected API response format',
        ));
      }

      return Left(ServerFailure(
        message: 'Failed to fetch exchange rate',
        statusCode: response.statusCode,
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Failure _handleApiError(String? errorType) {
    switch (errorType) {
      case 'unsupported-code':
        return ServerFailure(
          message: 'Unsupported currency code',
          statusCode: 400,
        );
      case 'malformed-request':
        return ServerFailure(
          message: 'Malformed request',
          statusCode: 400,
        );
      case 'invalid-key':
        return ServerFailure(
          message: 'Invalid API key',
          statusCode: 401,
        );
      case 'inactive-account':
        return ServerFailure(
          message: 'Inactive account',
          statusCode: 403,
        );
      case 'quota-reached':
        return ServerFailure(
          message: 'API quota reached',
          statusCode: 429,
        );
      default:
        return UnknownFailure(
          message: 'Unknown API error: $errorType',
        );
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure(message: 'Connection timeout');
    }

    if (e.type == DioExceptionType.connectionError) {
      return NetworkFailure(message: 'No internet connection');
    }

    if (e.response != null) {
      return ServerFailure(
        message: 'Server error',
        statusCode: e.response!.statusCode ?? 500,
      );
    }

    return UnknownFailure(message: e.message ?? 'Unknown error');
  }
}
```

---

## 📦 Step 4: Exchange Rate Local Data Source

**File:** `data/lib/src/data_source/local/exchange_rate_local_data_source.dart`

```dart
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
  DateTime? getLastUpdateDate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  });

  /// Check if rate was updated today
  bool wasUpdatedToday({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  });

  /// Clear all cached exchange rates
  Future<void> clearCache();
}

class ExchangeRateLocalDataSourceImpl
    implements ExchangeRateLocalDataSource {
  final SharedPreferences _prefs;

  ExchangeRateLocalDataSourceImpl({required SharedPreferences prefs})
      : _prefs = prefs;

  static const String _keyPrefix = 'exchange_rate_';

  /// Generate cache key: exchange_rate_vnd_usd
  String _getCacheKey(String base, String target) {
    return '$_keyPrefix${base.toLowerCase()}_${target.toLowerCase()}';
  }

  @override
  Future<ExchangeRateModel?> getCachedExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  }) async {
    final key = _getCacheKey(baseCurrency, targetCurrency);
    final jsonString = _prefs.getString(key);

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
    final key = _getCacheKey(rate.baseCurrency, rate.targetCurrency);
    final jsonString = jsonEncode(rate.toCacheJson());
    await _prefs.setString(key, jsonString);
  }

  @override
  DateTime? getLastUpdateDate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  }) {
    final cached = getCachedExchangeRate(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
    );

    // Use synchronous approach for simple check
    final key = _getCacheKey(baseCurrency, targetCurrency);
    final jsonString = _prefs.getString(key);

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
  bool wasUpdatedToday({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  }) {
    final lastUpdate = getLastUpdateDate(
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
    final keys = _prefs.getKeys()
        .where((k) => k.startsWith(_keyPrefix))
        .toList();

    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
```

---

## 📦 Step 5: Exchange Rate Repository

**File:** `domain/lib/src/repository/exchange_rate_repository.dart`

```dart
import 'package:domain/domain.dart';

abstract class ExchangeRateRepository {
  /// Get exchange rate with smart caching:
  /// - Check if updated today → return cache
  /// - If not updated today → fetch from API
  /// - If API fails → return cached (yesterday's value)
  /// - If no cache and API fails → return default value
  Future<Either<Failure, ExchangeRateEntity>> getExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
    double defaultRate = 25000.0,
  });
}
```

**File:** `data/lib/src/repository/exchange_rate_repository_impl.dart`

```dart
import 'package:domain/domain.dart';

import '../data_source/local/exchange_rate_local_data_source.dart';
import '../data_source/remote/exchange_rate_remote_data_source.dart';
import '../mapper/exchange_rate_mapper.dart';
import '../model/exchange_rate_model.dart';
import '../../../../app_config/di.dart';
import '../../../../app_config/env_config.dart';

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  final ExchangeRateRemoteDataSource _remoteDataSource;
  final ExchangeRateLocalDataSource _localDataSource;
  final ExchangeRateMapper _mapper;

  ExchangeRateRepositoryImpl({
    required ExchangeRateRemoteDataSource remoteDataSource,
    required ExchangeRateLocalDataSource localDataSource,
    ExchangeRateMapper? mapper,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _mapper = mapper ?? ExchangeRateMapper();

  @override
  Future<Either<Failure, ExchangeRateEntity>> getExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
    double defaultRate = 25000.0,
  }) async {
    try {
      // Step 1: Check if rate was updated today
      final wasUpdatedToday = _localDataSource.wasUpdatedToday(
        baseCurrency: baseCurrency,
        targetCurrency: targetCurrency,
      );

      if (wasUpdatedToday) {
        // Return cached value (already updated today)
        final cached = await _localDataSource.getCachedExchangeRate(
          baseCurrency: baseCurrency,
          targetCurrency: targetCurrency,
        );

        if (cached != null) {
          Logger.logI('✅ Exchange rate from cache (updated today)');
          return Right(_mapper.toEntity(cached));
        }
      }

      // Step 2: Need to fetch from API (not updated today or no cache)
      Logger.logI('🔄 Fetching exchange rate from API...');

      final appConfig = sl.get<AppConfig>() as EnvConfig;
      final apiKey = appConfig.exchangeRateApiKey;

      if (apiKey.isEmpty) {
        Logger.logE('❌ Exchange Rate API key is not configured');
        // Fallback to cache or default
        return await _fallbackToCacheOrDefault(defaultRate);
      }

      final apiResult = await _remoteDataSource.getExchangeRate(
        baseCurrency: baseCurrency,
        targetCurrency: targetCurrency,
        apiKey: apiKey,
      );

      return await apiResult.fold(
        onSuccess: (model) async {
          // API success → save to cache
          await _localDataSource.saveExchangeRate(model);
          Logger.logI('✅ Exchange rate fetched from API and cached');
          return Right(_mapper.toEntity(model));
        },
        onError: (failure) async {
          // API failed → fallback to cache or default
          Logger.logE('❌ API failed: ${failure.message}');
          return await _fallbackToCacheOrDefault(defaultRate);
        },
      );
    } catch (e) {
      Logger.logE('❌ Exchange rate repository error', e);
      return await _fallbackToCacheOrDefault(defaultRate);
    }
  }

  /// Fallback logic:
  /// 1. Try to use cached value (yesterday's rate)
  /// 2. If no cache → use default value from config
  Future<Either<Failure, ExchangeRateEntity>> _fallbackToCacheOrDefault(
    double defaultRate,
  ) async {
    // Try to get from cache (yesterday's value is better than default)
    final cached = await _localDataSource.getCachedExchangeRate(
      baseCurrency: 'VND',
      targetCurrency: 'USD',
    );

    if (cached != null) {
      Logger.logI('✅ Using cached exchange rate (yesterday\'s value)');
      return Right(_mapper.toEntity(cached));
    }

    // No cache available → use default value
    Logger.logI('⚠️ Using default exchange rate: $defaultRate');
    final defaultModel = ExchangeRateModel(
      baseCurrency: 'VND',
      targetCurrency: 'USD',
      conversionRate: defaultRate,
      lastUpdateDate: DateTime.now(),
      source: 'default',
      isFromCache: false,
    );

    // Save default to cache for future use
    await _localDataSource.saveExchangeRate(defaultModel);

    return Right(_mapper.toEntity(defaultModel));
  }
}
```

---

## 📦 Step 6: Exchange Rate Mapper

**File:** `data/lib/src/mapper/exchange_rate_mapper.dart`

```dart
import 'package:domain/domain.dart';

import '../model/exchange_rate_model.dart';
import 'base_mapper.dart';

class ExchangeRateMapper extends BaseMapper<ExchangeRateEntity, ExchangeRateModel> {
  @override
  ExchangeRateEntity toEntity(ExchangeRateModel model) {
    return ExchangeRateEntity(
      baseCurrency: model.baseCurrency,
      targetCurrency: model.targetCurrency,
      conversionRate: model.conversionRate,
      lastUpdateDate: model.lastUpdateDate,
      nextUpdateDate: model.nextUpdateDate,
      source: model.source,
      isFromCache: model.isFromCache,
    );
  }

  @override
  ExchangeRateModel toModel(ExchangeRateEntity entity) {
    return ExchangeRateModel(
      baseCurrency: entity.baseCurrency,
      targetCurrency: entity.targetCurrency,
      conversionRate: entity.conversionRate,
      lastUpdateDate: entity.lastUpdateDate,
      nextUpdateDate: entity.nextUpdateDate,
      source: entity.source,
      isFromCache: entity.isFromCache,
    );
  }
}
```

---

## 📦 Step 7: Currency Converter Service

**File:** `lib/src/core/services/currency_converter_service.dart`

```dart
import 'package:domain/domain.dart';

import '../../../app_config/di.dart';
import '../../helpers/other_helpers.dart';

/// Service để convert và format currency
class CurrencyConverterService {
  final ExchangeRateRepository _exchangeRateRepository;
  final double _defaultRate;

  CurrencyConverterService({
    ExchangeRateRepository? exchangeRateRepository,
    double? defaultRate,
  })  : _exchangeRateRepository =
            exchangeRateRepository ?? sl.get<ExchangeRateRepository>(),
        _defaultRate = defaultRate ?? 25000.0;

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
    
    final formatted = amount.toStringAsFixed(decimalPlaces);
    final parts = formatted.split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    if (parts.length > 1 && decimalPlaces > 0) {
      return '$symbol$integerPart.${parts[1]}';
    }
    
    return '$symbol$integerPart';
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
}
```

---

## 📦 Step 8: Currency Selection Dialog

**File:** `lib/src/presentation/widgets/dialog/currency_selection_dialog.dart`

```dart
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../helpers/other_helpers.dart';

class CurrencySelectionDialog extends StatelessWidget {
  final ExchangeRateEntity? exchangeRate;
  final Function(String selectedCurrency) onCurrencySelected;

  const CurrencySelectionDialog({
    super.key,
    this.exchangeRate,
    required this.onCurrencySelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemes.light;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tr(LocaleKeys.selectCurrency),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (exchangeRate != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.tr(LocaleKeys.exchangeRate)}: 1 USD = ${Helper().formatCurrency(exchangeRate!.conversionRate)} VND',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildCurrencyOption(
              context,
              currency: 'VND',
              symbol: '₫',
              label: l10n.tr(LocaleKeys.vietnameseDong),
            ),
            const SizedBox(height: 12),
            _buildCurrencyOption(
              context,
              currency: 'USD',
              symbol: '\$',
              label: l10n.tr(LocaleKeys.usDollar),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(
    BuildContext context, {
    required String currency,
    required String symbol,
    required String label,
  }) {
    final theme = AppThemes.light;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onCurrencySelected(currency);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📦 Step 9: Update Print Service

**File:** `lib/src/core/services/print_service.dart`

Thêm parameters và logic conversion:

```dart
static Future<void> printInvoice({
  required int sellId,
  int? taxId,
  required BuildContext context,
  required String name,
  required String cashier,
  required String unit,
  required int locationId,
  required AppLocalizations l10n,
  required List<ProductEntity> products,
  String currency = 'VND',  // NEW
  ExchangeRateEntity? exchangeRate,  // NEW
}) async {
  // ... existing code ...

  final Uint8List pdfBytes = await _buildPdf(
    products: products,
    layoutBill: billEntity,
    sell: sellEntity,
    contact: contactEntity,
    unit: unit,
    l10n: l10n,
    cashier: cashier,
    currency: currency,  // Pass currency
    exchangeRate: exchangeRate,  // Pass exchange rate
  );

  // ... existing code ...
}

static Future<Uint8List> _buildPdf({
  required List<ProductEntity> products,
  required LayoutBillEntity layoutBill,
  required SellEntity sell,
  required String unit,
  required String cashier,
  ContactEntity? contact,
  required AppLocalizations l10n,
  String currency = 'VND',  // NEW
  ExchangeRateEntity? exchangeRate,  // NEW
}) {
  // ... existing code ...

  // Currency conversion logic
  final bool isUSD = currency.toUpperCase() == 'USD';
  final double conversionRate = exchangeRate?.conversionRate ?? 1.0;
  final String currencySymbol = isUSD ? '\$' : '₫';
  final int decimalPlaces = isUSD ? 2 : 0;

  // Convert total
  final double total = sell.sellLines.fold(0, (e, s) {
    // ... existing discount calculation ...
    final lineTotal = subtotal - discount;
    return e + lineTotal;
  });

  final double convertedTotal = isUSD ? total / conversionRate : total;

  // Convert payment amounts
  final convertedPayments = sell.payments.map((payment) {
    final amount = payment.amount ?? 0.0;
    final convertedAmount = isUSD ? amount / conversionRate : amount;
    return payment.copyWith(amount: convertedAmount);
  }).toList();

  // Helper để format currency
  String formatCurrencyWithSymbol(double amount) {
    final formatted = amount.toStringAsFixed(decimalPlaces);
    final parts = formatted.split('.');
    final integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    
    if (parts.length > 1 && decimalPlaces > 0) {
      return '$currencySymbol$integerPart.${parts[1]}';
    }
    
    return '$currencySymbol$integerPart';
  }

  // ... trong PDF generation, replace Helper().formatCurrency() với formatCurrencyWithSymbol()
  // Ví dụ:
  // Thay: Helper().formatCurrency(lineTotal)
  // Bằng: formatCurrencyWithSymbol(isUSD ? lineTotal / conversionRate : lineTotal)

  // ... existing code ...
}
```

---

## 📦 Step 10: Integrate vào Print Flow

**File:** `lib/src/presentation/pages/pos/pos_bloc.dart` hoặc nơi gọi print

```dart
Future<void> _printInvoice(int sellId) async {
  try {
    final currencyConverter = sl.get<CurrencyConverterService>();
    
    // Get current exchange rate (cached or from API)
    final exchangeRate = await currencyConverter.getCurrentRate();
    
    // Show currency selection dialog
    final selectedCurrency = await showDialog<String>(
      context: context,
      builder: (context) => CurrencySelectionDialog(
        exchangeRate: exchangeRate,
        onCurrencySelected: (currency) {
          Navigator.of(context).pop(currency);
        },
      ),
    );

    if (selectedCurrency == null) return; // User cancelled

    // Validate exchange rate if USD selected
    if (selectedCurrency == 'USD') {
      if (exchangeRate == null || exchangeRate.conversionRate <= 0) {
        ToastManager.showError(
          context,
          'Cannot get exchange rate. Please try again later.',
        );
        return;
      }
    }

    // Get sell data and products
    final sellResult = await _getSellById(sellId);
    final productsResult = await _getProductsForSell(sellId);

    await sellResult.fold(
      onSuccess: (sell) async {
        await productsResult.fold(
          onSuccess: (products) async {
            // Print with selected currency
            await PrintService.printInvoice(
              sellId: sellId,
              taxId: null, // or get from sell
              context: context,
              name: sell.invoiceNo ?? '',
              cashier: _getCurrentUser()?.name ?? '',
              unit: selectedCurrency,
              locationId: sell.locationId ?? 0,
              l10n: AppLocalizations.of(context),
              products: products,
              currency: selectedCurrency,
              exchangeRate: exchangeRate,
            );
          },
          onError: (failure) {
            ToastManager.showError(context, failure.message);
          },
        );
      },
      onError: (failure) {
        ToastManager.showError(context, failure.message);
      },
    );
  } catch (e) {
    Logger.logE('Print invoice error', e);
    ToastManager.showError(context, 'Failed to print invoice');
  }
}
```

---

## 📦 Step 11: Register Dependencies

**File:** `lib/app_config/di.dart`

```dart
void _registerDataSources() {
  // ... existing data sources ...

  sl.registerLazy<ExchangeRateRemoteDataSource>(
    () => ExchangeRateRemoteDataSourceImpl(
      dio: sl.get<Dio>(), // or use ApiClient
    ),
  );

  sl.registerLazy<ExchangeRateLocalDataSource>(
    () => ExchangeRateLocalDataSourceImpl(
      prefs: sl.get<SharedPreferences>(),
    ),
  );
}

void _registerRepositories() {
  // ... existing repositories ...

  sl.registerLazy<ExchangeRateRepository>(() => ExchangeRateRepositoryImpl(
        remoteDataSource: sl.get<ExchangeRateRemoteDataSource>(),
        localDataSource: sl.get<ExchangeRateLocalDataSource>(),
      ));
}

void _registerServices() {
  // ... existing services ...

  sl.registerLazy<CurrencyConverterService>(() => CurrencyConverterService(
        exchangeRateRepository: sl.get<ExchangeRateRepository>(),
      ));
}
```

---

## 📦 Step 12: Add Localization Keys

**File:** `lib/src/core/localization/locale_keys.dart`

```dart
class LocaleKeys {
  // ... existing keys ...
  
  static const selectCurrency = 'select_currency';
  static const exchangeRate = 'exchange_rate';
  static const vietnameseDong = 'vietnamese_dong';
  static const usDollar = 'us_dollar';
}
```

**Translation files:**

**File:** `lib/src/core/localization/lang/vi.json`

```json
{
  "select_currency": "Chọn loại tiền tệ",
  "exchange_rate": "Tỉ giá",
  "vietnamese_dong": "Đồng Việt Nam",
  "us_dollar": "Đô la Mỹ"
}
```

---

## 🔄 Cache & Update Logic Flow

### Flow Diagram:

```
┌─────────────────────────────────────┐
│  Get Exchange Rate Request          │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Check: Updated Today?              │
│  (wasUpdatedToday())                │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┐
        │             │
     YES│             │NO
        │             │
        ▼             ▼
┌──────────────┐  ┌──────────────────────┐
│ Return Cache │  │  Fetch from API      │
│ (updated     │  │  (once per day)      │
│  today)      │  └──────────┬───────────┘
└──────────────┘             │
                             ▼
                    ┌─────────────────┐
                    │  API Success?   │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
                 YES│                 │NO
                    │                 │
                    ▼                 ▼
        ┌──────────────────┐  ┌──────────────────┐
        │  Save to Cache   │  │  Fallback Logic  │
        │  Return Rate     │  │  1. Try Cache    │
        └──────────────────┘  │     (yesterday)  │
                              │  2. Use Default  │
                              │     (config)     │
                              └──────────────────┘
```

### Key Points:

1. **Daily Update Check**: Sử dụng `wasUpdatedToday()` để check date, không phải timestamp
2. **One API Call Per Day**: Chỉ gọi API nếu chưa update hôm nay
3. **Fallback Chain**:
   - API success → save và return
   - API fail → try cached (yesterday's value)
   - No cache → use default from config
4. **Default Value**: Được config trong `EnvConfig.defaultExchangeRate` (default: 25000.0)

---

## ✅ Testing Checklist

### Exchange Rate API Testing

- [ ] Test API success response parsing
- [ ] Test API error responses (unsupported-code, invalid-key, etc.)
- [ ] Test network timeout/error handling
- [ ] Test API quota reached (429 error)

### Caching Logic Testing

- [ ] Test cache save và load
- [ ] Test `wasUpdatedToday()` returns true khi cùng ngày
- [ ] Test `wasUpdatedToday()` returns false khi khác ngày
- [ ] Test mỗi ngày chỉ gọi API 1 lần
- [ ] Test fallback to cache khi API fail
- [ ] Test fallback to default khi không có cache

### Currency Conversion Testing

- [ ] Test convert VND → USD đúng
- [ ] Test convert USD → VND đúng
- [ ] Test format currency với symbol (₫ và $)
- [ ] Test decimal places (USD: 2, VND: 0)

### Print Invoice Testing

- [ ] Test currency selection dialog hiển thị
- [ ] Test select VND và print
- [ ] Test select USD và print
- [ ] Test print với exchange rate từ cache
- [ ] Test print với exchange rate từ API
- [ ] Test print với default rate (API fail, no cache)
- [ ] Test error handling khi không có exchange rate

---

## ⚠️ Important Notes

1. **API Key Configuration**: Đảm bảo API key được config đúng trong `.env` files
2. **Default Rate**: Default rate nên được set phù hợp với business (recommend: 25000.0)
3. **Cache Key Format**: Luôn dùng lowercase: `exchange_rate_vnd_usd`
4. **Date Comparison**: Luôn so sánh ngày, không phải giờ/phút để đảm bảo 1 lần/ngày
5. **Error Handling**: Luôn có fallback chain để đảm bảo app không crash
6. **Logging**: Log các events quan trọng để debug (API calls, cache hits, fallbacks)

---

## 🚀 Implementation Priority

### Phase 1: Core Infrastructure (High Priority)
1. ✅ Add API key to config
2. ✅ Create Entity & Model
3. ✅ Create Remote & Local Data Sources
4. ✅ Create Repository với smart caching logic
5. ✅ Test API integration và caching

### Phase 2: Currency Converter (Medium Priority)
1. ✅ Create CurrencyConverterService
2. ✅ Create Mapper
3. ✅ Register dependencies
4. ✅ Test conversion logic

### Phase 3: UI Integration (Medium Priority)
1. ✅ Create Currency Selection Dialog
2. ✅ Update Print Service
3. ✅ Integrate vào print flow
4. ✅ Add localization

### Phase 4: Testing & Polish (Low Priority)
1. ✅ Test tất cả scenarios
2. ✅ Error handling improvements
3. ✅ UI/UX polish
4. ✅ Documentation

---

## 📚 API Reference

- ExchangeRate-API Documentation: https://www.exchangerate-api.com/docs
- API Endpoint: `GET https://v6.exchangerate-api.com/v6/{API_KEY}/pair/{BASE}/{TARGET}`
- Supported Currencies: https://www.exchangerate-api.com/docs/supported-currencies
- Error Codes: See document above
