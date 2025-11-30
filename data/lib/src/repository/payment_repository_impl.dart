import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/payment_remote_data_source.dart';

/// Implementation of [PaymentRepository]
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  const PaymentRepositoryImpl({
    required PaymentRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<PaymentMethodEntity>>> getPaymentMethods() async {
    if (!await _networkInfo.isConnected) {
      return getLocalPaymentMethods();
    }

    try {
      final methods = await _remoteDataSource.getPaymentMethods();
      final entities = methods.map(_mapMethodToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<PaymentAccountEntity>>> getPaymentAccounts() async {
    if (!await _networkInfo.isConnected) {
      return getLocalPaymentAccounts();
    }

    try {
      final accounts = await _remoteDataSource.getPaymentAccounts();
      final entities = accounts.map(_mapAccountToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> syncPaymentMethods() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final methods = await _remoteDataSource.getPaymentMethods();
      await _localDataSource.insert('payment_methods', jsonEncode(methods));
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> syncPaymentAccounts() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final accounts = await _remoteDataSource.getPaymentAccounts();
      await _localDataSource.insert('payment_accounts', jsonEncode(accounts));
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<PaymentMethodEntity>>> getLocalPaymentMethods() async {
    try {
      final data = await _localDataSource.get('payment_methods');
      if (data == null) {
        return const Success([]);
      }

      final List<dynamic> methodList = data is String ? jsonDecode(data) : data;
      final entities = methodList.map((json) {
        if (json is Map<String, dynamic>) {
          return _mapMethodToEntity(json);
        }
        return const PaymentMethodEntity(name: 'unknown');
      }).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<PaymentAccountEntity>>> getLocalPaymentAccounts() async {
    try {
      final data = await _localDataSource.get('payment_accounts');
      if (data == null) {
        return const Success([]);
      }

      final List<dynamic> accountList = data is String ? jsonDecode(data) : data;
      final entities = accountList
          .map((json) => _mapAccountToEntity(json as Map<String, dynamic>))
          .toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getCustomerDue(int customerId) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final response = await _remoteDataSource.getCustomerDue(customerId);
      return Success(response);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> postContactPayment({
    required int contactId,
    required double amount,
    required String method,
    String? note,
    int? accountId,
    DateTime? paidOn,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'contact_id': contactId,
        'amount': amount,
        'method': method,
        if (note != null) 'note': note,
        if (accountId != null) 'account_id': accountId,
        if (paidOn != null) 'paid_on': paidOn.toIso8601String().split('T')[0],
      };

      await _remoteDataSource.postContactPayment(data);
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  PaymentMethodEntity _mapMethodToEntity(Map<String, dynamic> json) {
    // Payment methods come as {method_name: label}
    final entry = json.entries.first;
    return PaymentMethodEntity(
      name: entry.key,
      label: entry.value?.toString(),
      isActive: true,
    );
  }

  PaymentAccountEntity _mapAccountToEntity(Map<String, dynamic> json) {
    return PaymentAccountEntity(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      name: json['name'] as String,
      accountNumber: json['account_number'] as String? ?? '',
      accountType: json['account_type'] as String?,
      note: json['note'] as String?,
      isActive: json['is_active'] == 1,
      isClosed: json['is_closed'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}




