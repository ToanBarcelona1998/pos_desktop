import '../../core/api_client.dart';
import '../../model/business_model.dart';

/// Remote data source for business operations
abstract class BusinessRemoteDataSource {
  /// Get business details
  Future<BusinessModel> getBusinessDetails();
}

/// Implementation of [BusinessRemoteDataSource]
class BusinessRemoteDataSourceImpl implements BusinessRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const BusinessRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<BusinessModel> getBusinessDetails() async {
    final response = await _apiClient.get(_endpoint);
    return BusinessModel.fromJson(response['data'] ?? response);
  }
}












