import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/category_entity.dart';
import '../../repository/category_repository.dart';

/// Use case for getting all categories
class GetCategoriesUseCase implements UseCaseNoParams<List<CategoryEntity>> {
  final CategoryRepository _repository;

  const GetCategoriesUseCase(this._repository);

  @override
  Future<Result<List<CategoryEntity>>> call() async {
    return await _repository.getCategories();
  }
}











