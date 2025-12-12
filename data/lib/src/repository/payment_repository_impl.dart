import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/payment_remote_data_source.dart';

/// Implementation of [PaymentRepository]
class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;

  const PaymentRepositoryImpl({
    required PaymentRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Result<List<PaymentMethodEntity>>> getPaymentMethods() async {
    try {
      final methods = await _remoteDataSource.getPaymentMethods();
      final entities = methods.map(_mapMethodToEntity).toList();
      return Success(entities);
    } catch (e) {
      Logger.logE('Failed to fetch payment methods from server, trying local', e);
      return getLocalPaymentMethods();
    }
  }

  @override
  Future<Result<List<PaymentAccountEntity>>> getPaymentAccounts() async {
    try {
      final accounts = await _remoteDataSource.getPaymentAccounts();
      final entities = accounts.map(_mapAccountToEntity).toList();
      return Success(entities);
    } catch (e) {
      Logger.logE('Failed to fetch payment accounts from server, trying local', e);
      return getLocalPaymentAccounts();
    }
  }

  @override
  Future<Result<void>> syncPaymentMethods() async {
    try {
      final methods = await _remoteDataSource.getPaymentMethods();
      await _localDataSource.insert('payment_methods', jsonEncode(methods));
      return const Success(null);
    } catch (e) {
      Logger.logE('Error syncing payment methods', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> syncPaymentAccounts() async {
    try {
      final accounts = await _remoteDataSource.getPaymentAccounts();
      await _localDataSource.insert('payment_accounts', jsonEncode(accounts));
      return const Success(null);
    } catch (e) {
      Logger.logE('Error syncing payment accounts', e);
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
  Future<Result<List<PaymentAccountEntity>>> getPaymentAccountsByType(
    String paymentMethod,
  ) async {
    try {
      final accountsResult = await getLocalPaymentAccounts();
      return accountsResult.fold(
        onSuccess: (accounts) {
          // Filter by payment method and only active, non-closed accounts
          final filtered = accounts
              .where((account) =>
                  account.paymentMethod?.toLowerCase() == paymentMethod.toLowerCase() &&
                  !account.isClosed)
              .toList();
          return Success(filtered);
        },
        onError: (failure) => Error(failure),
      );
    } catch (e) {
      Logger.logE('Error getting payment accounts by type', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getCustomerDue(int customerId) async {
    try {
      final response = await _remoteDataSource.getCustomerDue(customerId);
      return Success(response);
    } catch (e) {
      Logger.logE('Error getting customer due', e);
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
      Logger.logE('Error posting contact payment', e);
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
    // Parse account_details
    List<PaymentAccountDetailEntity>? accountDetails;
    if (json['account_details'] != null) {
      final details = json['account_details'] as List<dynamic>?;
      if (details != null) {
        accountDetails = details
            .map((item) {
              if (item is Map<String, dynamic>) {
                return PaymentAccountDetailEntity(
                  label: item['label']?.toString(),
                  value: item['value']?.toString(),
                );
              }
              return null;
            })
            .whereType<PaymentAccountDetailEntity>()
            .toList();
      }
    }

    return PaymentAccountEntity(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      name: json['name'] as String,
      accountNumber: json['account_number']?.toString(),
      accountType: json['account_type']?.toString(),
      note: json['note']?.toString(),
      isClosed: json['is_closed'] == 1 || json['is_closed'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      paymentMethod: json['payment_method']?.toString(),
      bankBin: json['bank_bin']?.toString(),
      imageEWallet: json['image_e_wallet']?.toString(),
      cachedImagePath: json['cached_image_path']?.toString(),
      accountTypeId: json['account_type_id'] != null
          ? (json['account_type_id'] is int
              ? json['account_type_id'] as int
              : int.tryParse(json['account_type_id'].toString()))
          : null,
      accountDetails: accountDetails,
    );
  }
}












