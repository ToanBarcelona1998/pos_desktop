import 'package:domain/domain.dart';

import '../data_source/local/exchange_rate_local_data_source.dart';
import '../data_source/remote/exchange_rate_remote_data_source.dart';
import '../mapper/exchange_rate_mapper.dart';
import '../model/exchange_rate_model.dart';

class ExchangeRateRepositoryImpl implements ExchangeRateRepository {
  final ExchangeRateRemoteDataSource _remoteDataSource;
  final ExchangeRateLocalDataSource _localDataSource;
  final ExchangeRateMapper _mapper;
  final String _apiKey;
  final String _baseUrl;
  final double _defaultRate;

  ExchangeRateRepositoryImpl({
    required ExchangeRateRemoteDataSource remoteDataSource,
    required ExchangeRateLocalDataSource localDataSource,
    ExchangeRateMapper? mapper,
    required String apiKey,
    required String baseUrl,
    double defaultRate = 25000.0,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _mapper = mapper ?? const ExchangeRateMapper(),
        _apiKey = apiKey,
        _baseUrl = baseUrl,
        _defaultRate = defaultRate;

  @override
  Future<Result<ExchangeRateEntity>> getExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
    double defaultRate = 25000.0,
  }) async {
    try {
      // Step 1: Check if rate was updated today
      final wasUpdatedToday = await _localDataSource.wasUpdatedToday(
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
          return Success(_mapper.toEntity(cached));
        }
      }

      // Step 2: Need to fetch from API (not updated today or no cache)
      Logger.logI('🔄 Fetching exchange rate from API...');

      if (_apiKey.isEmpty) {
        Logger.logE('❌ Exchange Rate API key is not configured');
        // Fallback to cache or default
        return await _fallbackToCacheOrDefault(baseCurrency, targetCurrency, defaultRate);
      }

      final apiResult = await _remoteDataSource.getExchangeRate(
        baseCurrency: baseCurrency,
        targetCurrency: targetCurrency,
        apiKey: _apiKey,
        baseUrl: _baseUrl,
      );

      return await apiResult.fold(
        onSuccess: (model) async {
          // API success → save to cache
          await _localDataSource.saveExchangeRate(model);
          Logger.logI('✅ Exchange rate fetched from API and cached');
          return Success(_mapper.toEntity(model));
        },
        onError: (failure) async {
          // API failed → fallback to cache or default
          Logger.logE('❌ API failed: ${failure.message}');
          return await _fallbackToCacheOrDefault(baseCurrency, targetCurrency, defaultRate);
        },
      );
    } catch (e) {
      Logger.logE('❌ Exchange rate repository error', e);
      return await _fallbackToCacheOrDefault(baseCurrency, targetCurrency, defaultRate);
    }
  }

  @override
  Future<Result<void>> saveExchangeRate(ExchangeRateEntity rate) async {
    try {
      final model = _mapper.toModel(rate);
      await _localDataSource.saveExchangeRate(model);
      return const Success(null);
    } catch (e) {
      Logger.logE('Error saving exchange rate', e);
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<ExchangeRateEntity?>> getCachedExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
  }) async {
    try {
      final model = await _localDataSource.getCachedExchangeRate(
        baseCurrency: baseCurrency,
        targetCurrency: targetCurrency,
      );
      if (model != null) {
        return Success(_mapper.toEntity(model));
      }
      return const Success(null);
    } catch (e) {
      Logger.logE('Error getting cached exchange rate', e);
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  /// Fallback logic:
  /// 1. Try to use cached value (yesterday's rate)
  /// 2. If no cache → use default value from config
  Future<Result<ExchangeRateEntity>> _fallbackToCacheOrDefault(
    String baseCurrency,
    String targetCurrency,
    double? defaultRate,
  ) async {
    final rateToUse = defaultRate ?? _defaultRate;
    // Try to get from cache (yesterday's value is better than default)
    final cached = await _localDataSource.getCachedExchangeRate(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
    );

    if (cached != null) {
      Logger.logI('✅ Using cached exchange rate (yesterday\'s value)');
      return Success(_mapper.toEntity(cached));
    }

    // No cache available → use default value
    Logger.logI('⚠️ Using default exchange rate: $rateToUse');
    final defaultModel = ExchangeRateModel(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
      conversionRate: rateToUse,
      lastUpdateDate: DateTime.now(),
      source: 'default',
      isFromCache: false,
    );

    // Save default to cache for future use
    await _localDataSource.saveExchangeRate(defaultModel);

    return Success(_mapper.toEntity(defaultModel));
  }
}
