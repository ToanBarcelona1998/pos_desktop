import '../core/result.dart';
import '../entity/report_entity.dart';

/// Repository interface for report operations
abstract class ReportRepository {
  /// Get profit loss report
  Future<Result<ProfitLossReportEntity>> getProfitLossReport({
    DateTime? startDate,
    DateTime? endDate,
    int? locationId,
  });

  /// Get product stock report
  Future<Result<List<ProductStockReportEntity>>> getProductStockReport({
    int? locationId,
  });
}









