import '../core/result.dart';
import '../entity/layout_bill_entity.dart';

/// Repository for layout bill operations
abstract class LayoutBillRepository {
  /// Get layout bill information
  Future<Result<LayoutBillEntity>> getLayoutBill(int locationId);
}

