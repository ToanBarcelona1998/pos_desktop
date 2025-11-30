import '../core/result.dart';
import '../entity/category_entity.dart';

/// Repository interface for category operations
abstract class CategoryRepository {
  /// Get all categories
  Future<Result<List<CategoryEntity>>> getCategories();

  /// Get category by ID
  Future<Result<CategoryEntity>> getCategoryById(int id);

  /// Sync categories from remote to local
  Future<Result<void>> syncCategories();

  /// Get categories from local storage
  Future<Result<List<CategoryEntity>>> getLocalCategories();

  /// Get sub-categories for a parent category
  Future<Result<List<CategoryEntity>>> getSubCategories(int parentId);
}





