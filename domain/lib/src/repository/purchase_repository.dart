import '../core/result.dart';
import '../entity/purchase_entity.dart';

/// Repository interface for purchase operations
abstract class PurchaseRepository {
  /// Get all purchases
  Future<Result<List<PurchaseEntity>>> getPurchases({
    int? userId,
    int? businessId,
  });

  /// Get purchase by ID
  Future<Result<PurchaseEntity>> getPurchaseById(int id);

  /// Create a new purchase
  Future<Result<PurchaseEntity>> createPurchase(Map<String, dynamic> data);

  /// Update a purchase
  Future<Result<PurchaseEntity>> updatePurchase(int id, Map<String, dynamic> data);

  /// Delete a purchase
  Future<Result<void>> deletePurchase(int id);
}

