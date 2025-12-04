import '../../core/api_client.dart';
import '../../model/tax_model.dart';

/// Remote data source for tax operations
abstract class TaxRemoteDataSource {
  /// Get all taxes
  Future<List<TaxModel>> getTaxes();
}

/// Implementation of [TaxRemoteDataSource]
class TaxRemoteDataSourceImpl implements TaxRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const TaxRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<TaxModel>> getTaxes() async {
    final response = await _apiClient.get(_endpoint);
    final data = response['data'] as List<dynamic>;
    return data
        .map((json) => TaxModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}











