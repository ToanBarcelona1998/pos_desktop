import '../core/result.dart';
import '../entity/variation_entity.dart';

/// Repository interface for product variation operations
abstract class VariationRepository {
  /// Get variations with pagination
  Future<Result<VariationListResult>> getVariations(String url);

  /// Get variations for a product
  Future<Result<List<VariationEntity>>> getVariationsForProduct(int productId);

  /// Sync variations to local storage
  Future<Result<void>> syncVariations(int locationId);

  /// Get variations from local storage
  Future<Result<List<VariationEntity>>> getLocalVariations();
}

/// Result class for paginated variation list
class VariationListResult {
  final List<VariationEntity> variations;
  final String? nextLink;

  const VariationListResult({
    required this.variations,
    this.nextLink,
  });

  bool get hasMore => nextLink != null && nextLink!.isNotEmpty;
}










