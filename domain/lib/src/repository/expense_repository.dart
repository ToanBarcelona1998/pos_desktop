import '../core/result.dart';
import '../entity/expense_entity.dart';

/// Repository interface for expense operations
abstract class ExpenseRepository {
  /// Get expense categories
  Future<Result<List<ExpenseCategoryEntity>>> getExpenseCategories();

  /// Create an expense
  Future<Result<ExpenseEntity>> createExpense({
    required int locationId,
    required int expenseCategoryId,
    required double totalAmount,
    String? refNo,
    String? additionalNotes,
    int? contactId,
    DateTime? transactionDate,
  });

  /// Get expenses
  Future<Result<List<ExpenseEntity>>> getExpenses({
    int? locationId,
    DateTime? startDate,
    DateTime? endDate,
  });
}








