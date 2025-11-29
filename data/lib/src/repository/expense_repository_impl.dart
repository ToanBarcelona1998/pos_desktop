import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/expense_remote_data_source.dart';

/// Implementation of [ExpenseRepository]
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ExpenseRepositoryImpl({
    required ExpenseRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<ExpenseCategoryEntity>>> getExpenseCategories() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final categories = await _remoteDataSource.getExpenseCategories();
      final entities = categories.map(_mapCategoryToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<ExpenseEntity>> createExpense({
    required int locationId,
    required int expenseCategoryId,
    required double totalAmount,
    String? refNo,
    String? additionalNotes,
    int? contactId,
    DateTime? transactionDate,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'location_id': locationId,
        'expense_category_id': expenseCategoryId,
        'final_total': totalAmount,
        if (refNo != null) 'ref_no': refNo,
        if (additionalNotes != null) 'additional_notes': additionalNotes,
        if (contactId != null) 'contact_id': contactId,
        if (transactionDate != null)
          'transaction_date': transactionDate.toIso8601String().split('T')[0],
      };

      final response = await _remoteDataSource.createExpense(data);
      return Success(_mapExpenseToEntity(response));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ExpenseEntity>>> getExpenses({
    int? locationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final query = <String, dynamic>{};
      if (locationId != null) query['location_id'] = locationId;
      if (startDate != null) query['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) query['end_date'] = endDate.toIso8601String().split('T')[0];

      final expenses = await _remoteDataSource.getExpenses(query: query);
      final entities = expenses.map(_mapExpenseToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  ExpenseCategoryEntity _mapCategoryToEntity(Map<String, dynamic> json) {
    return ExpenseCategoryEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      businessId: json['business_id'] as int,
      code: json['code'] as String?,
      parentId: json['parent_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  ExpenseEntity _mapExpenseToEntity(Map<String, dynamic> json) {
    return ExpenseEntity(
      id: json['id'] as int?,
      businessId: json['business_id'] as int,
      locationId: json['location_id'] as int,
      refNo: json['ref_no'] as String? ?? '',
      expenseCategoryId: json['expense_category_id'] as int,
      totalAmount: (json['final_total'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['payment_status'] as String? ?? 'due',
      additionalNotes: json['additional_notes'] as String?,
      contactId: json['contact_id'] as int?,
      userId: json['created_by'] as int?,
      transactionDate: json['transaction_date'] != null
          ? DateTime.tryParse(json['transaction_date'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

