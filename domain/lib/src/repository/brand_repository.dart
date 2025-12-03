import '../core/result.dart';
import '../entity/brand_entity.dart';

/// Abstract repository for brand operations.
/// This interface should be implemented in the data layer.
abstract class BrandRepository {
  /// Gets all brands.
  Future<Result<List<BrandEntity>>> getBrands();

  /// Gets a brand by ID.
  Future<Result<BrandEntity>> getBrandById(int id);

  /// Creates a new brand.
  Future<Result<BrandEntity>> createBrand({
    required String name,
    String? description,
    bool? useForRepair,
  });

  /// Updates an existing brand.
  Future<Result<BrandEntity>> updateBrand({
    required int id,
    String? name,
    String? description,
    bool? useForRepair,
  });

  /// Deletes a brand.
  Future<Result<void>> deleteBrand(int id);

  /// Searches brands by name.
  Future<Result<List<BrandEntity>>> searchBrands(String query);
}








