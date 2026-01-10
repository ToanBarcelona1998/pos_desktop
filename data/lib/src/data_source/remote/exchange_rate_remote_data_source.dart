import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;

import '../../model/exchange_rate_model.dart';

abstract class ExchangeRateRemoteDataSource {
  Future<Result<ExchangeRateModel>> getExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
    required String apiKey,
    required String baseUrl,
  });
}

class ExchangeRateRemoteDataSourceImpl
    implements ExchangeRateRemoteDataSource {
  final http.Client _client;

  ExchangeRateRemoteDataSourceImpl({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<Result<ExchangeRateModel>> getExchangeRate({
    String baseCurrency = 'VND',
    String targetCurrency = 'USD',
    required String apiKey,
    required String baseUrl,
  }) async {
    try {
      if (apiKey.isEmpty) {
        return const Error(ServerFailure(
          message: 'Exchange Rate API key is not configured',
          statusCode: 400,
        ));
      }

      final url = '$baseUrl/$apiKey/pair/$baseCurrency/$targetCurrency';
      final uri = Uri.parse(url);

      final response = await _client.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Check for API errors
        if (data['result'] == 'error') {
          final errorType = data['error-type'] as String?;
          return Error(_handleApiError(errorType));
        }

        // Success response
        if (data['result'] == 'success') {
          final model = ExchangeRateModel.fromApiJson(data);
          return Success(model);
        }

        return const Error(UnknownFailure(
          message: 'Unexpected API response format',
        ));
      }

      return Error(ServerFailure(
        message: 'Failed to fetch exchange rate',
        statusCode: response.statusCode,
      ));
    } on SocketException {
      return const Error(NetworkFailure(message: 'No internet connection'));
    } on TimeoutException catch (e) {
      return Error(NetworkFailure(message: e.message ?? 'Connection timeout'));
    } on FormatException {
      return const Error(UnknownFailure(message: 'Invalid response format'));
    } catch (e) {
      return Error(UnknownFailure(message: e.toString()));
    }
  }

  Failure _handleApiError(String? errorType) {
    switch (errorType) {
      case 'unsupported-code':
        return const ServerFailure(
          message: 'Unsupported currency code',
          statusCode: 400,
        );
      case 'malformed-request':
        return const ServerFailure(
          message: 'Malformed request',
          statusCode: 400,
        );
      case 'invalid-key':
        return const ServerFailure(
          message: 'Invalid API key',
          statusCode: 401,
        );
      case 'inactive-account':
        return const ServerFailure(
          message: 'Inactive account',
          statusCode: 403,
        );
      case 'quota-reached':
        return const ServerFailure(
          message: 'API quota reached',
          statusCode: 429,
        );
      default:
        return UnknownFailure(
          message: 'Unknown API error: $errorType',
        );
    }
  }
}
