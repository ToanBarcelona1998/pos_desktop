import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/expense_entity.dart';
import '../../repository/expense_repository.dart';

/// Use case for getting expense categories
class GetExpenseCategoriesUseCase implements UseCaseNoParams<List<ExpenseCategoryEntity>> {
  final ExpenseRepository _repository;

  const GetExpenseCategoriesUseCase(this._repository);

  @override
  Future<Result<List<ExpenseCategoryEntity>>> call() async {
    return await _repository.getExpenseCategories();
  }
}






