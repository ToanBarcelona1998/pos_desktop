import '../../core/api_client.dart';
import '../../model/location_model.dart';

/// Remote data source for location operations
abstract class LocationRemoteDataSource {
  /// Get all business locations
  Future<List<LocationModel>> getLocations();
}

/// Implementation of [LocationRemoteDataSource]
class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const LocationRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<LocationModel>> getLocations() async {
    final response = await _apiClient.get(_endpoint);
    final data = response['data'] as List<dynamic>?;
    return data
        ?.map((json) => LocationModel.fromJson(json as Map<String, dynamic>))
        .toList() ?? [];
  }
}

