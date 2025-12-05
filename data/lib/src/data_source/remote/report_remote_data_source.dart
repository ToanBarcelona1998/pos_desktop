import '../../core/api_client.dart';
import '../../model/report_model.dart';

/// Remote data source for report operations
abstract class ReportRemoteDataSource {
  /// Get profit loss report
  Future<ProfitLossReportModel> getProfitLossReport({Map<String, dynamic>? query});

  /// Get product stock report
  Future<List<ProductStockReportModel>> getProductStockReport({Map<String, dynamic>? query});
}

/// Implementation of [ReportRemoteDataSource]
class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final ApiClient _apiClient;
  final String _profitLossEndpoint;
  final String _productStockEndpoint;

  const ReportRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String profitLossEndpoint,
    required String productStockEndpoint,
  })  : _apiClient = apiClient,
        _profitLossEndpoint = profitLossEndpoint,
        _productStockEndpoint = productStockEndpoint;

  @override
  Future<ProfitLossReportModel> getProfitLossReport({Map<String, dynamic>? query}) async {
    final response = await _apiClient.get(_profitLossEndpoint, queryParams: query);
    return ProfitLossReportModel.fromJson(response['data'] ?? response);
  }

  @override
  Future<List<ProductStockReportModel>> getProductStockReport({Map<String, dynamic>? query}) async {
    final response = await _apiClient.get(_productStockEndpoint, queryParams: query);
    final data = response['data'] as List<dynamic>;
    return data
        .map((json) => ProductStockReportModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}












