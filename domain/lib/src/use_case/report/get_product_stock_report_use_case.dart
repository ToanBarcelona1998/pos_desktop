import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/report_entity.dart';
import '../../repository/report_repository.dart';

/// Use case for getting product stock report
class GetProductStockReportUseCase implements UseCase<List<ProductStockReportEntity>, int?> {
  final ReportRepository _repository;

  const GetProductStockReportUseCase(this._repository);

  @override
  Future<Result<List<ProductStockReportEntity>>> call(int? locationId) async {
    return await _repository.getProductStockReport(locationId: locationId);
  }
}





