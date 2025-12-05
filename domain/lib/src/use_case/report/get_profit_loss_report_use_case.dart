import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/report_entity.dart';
import '../../repository/report_repository.dart';

/// Parameters for get profit loss report use case
class GetProfitLossReportParams {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? locationId;

  const GetProfitLossReportParams({
    this.startDate,
    this.endDate,
    this.locationId,
  });
}

/// Use case for getting profit loss report
class GetProfitLossReportUseCase implements UseCase<ProfitLossReportEntity, GetProfitLossReportParams> {
  final ReportRepository _repository;

  const GetProfitLossReportUseCase(this._repository);

  @override
  Future<Result<ProfitLossReportEntity>> call(GetProfitLossReportParams params) async {
    return await _repository.getProfitLossReport(
      startDate: params.startDate,
      endDate: params.endDate,
      locationId: params.locationId,
    );
  }
}












