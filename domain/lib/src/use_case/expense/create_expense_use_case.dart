import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/expense_entity.dart';
import '../../repository/expense_repository.dart';

/// Parameters for create expense use case
class CreateExpenseParams {
  final int locationId;
  final int expenseCategoryId;
  final double totalAmount;
  final String? refNo;
  final String? additionalNotes;
  final int? contactId;
  final DateTime? transactionDate;

  const CreateExpenseParams({
    required this.locationId,
    required this.expenseCategoryId,
    required this.totalAmount,
    this.refNo,
    this.additionalNotes,
    this.contactId,
    this.transactionDate,
  });
}

/// Use case for creating an expense
class CreateExpenseUseCase implements UseCase<ExpenseEntity, CreateExpenseParams> {
  final ExpenseRepository _repository;

  const CreateExpenseUseCase(this._repository);

  @override
  Future<Result<ExpenseEntity>> call(CreateExpenseParams params) async {
    return await _repository.createExpense(
      locationId: params.locationId,
      expenseCategoryId: params.expenseCategoryId,
      totalAmount: params.totalAmount,
      refNo: params.refNo,
      additionalNotes: params.additionalNotes,
      contactId: params.contactId,
      transactionDate: params.transactionDate,
    );
  }
}









