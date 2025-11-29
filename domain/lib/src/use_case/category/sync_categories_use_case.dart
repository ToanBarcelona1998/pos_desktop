import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../repository/category_repository.dart';

/// Use case for syncing categories
class SyncCategoriesUseCase implements UseCaseNoParams<void> {
  final CategoryRepository _repository;

  const SyncCategoriesUseCase(this._repository);

  @override
  Future<Result<void>> call() async {
    return await _repository.syncCategories();
  }
}

