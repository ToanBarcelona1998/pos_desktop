import '../../core/api_client.dart';

/// Remote data source for field force operations
abstract class FieldForceRemoteDataSource {
  /// Create a new visit
  Future<Map<String, dynamic>> createVisit(Map<String, dynamic> data);

  /// Update visit status
  Future<Map<String, dynamic>> updateVisitStatus(int id, Map<String, dynamic> data);

  /// Get visits
  Future<List<Map<String, dynamic>>> getVisits({Map<String, dynamic>? query});
}

/// Implementation of [FieldForceRemoteDataSource]
class FieldForceRemoteDataSourceImpl implements FieldForceRemoteDataSource {
  final ApiClient _apiClient;
  final String _createEndpoint;
  final String _updateEndpoint;

  const FieldForceRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String createEndpoint,
    required String updateEndpoint,
  })  : _apiClient = apiClient,
        _createEndpoint = createEndpoint,
        _updateEndpoint = updateEndpoint;

  @override
  Future<Map<String, dynamic>> createVisit(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_createEndpoint, body: data);
    return response;
  }

  @override
  Future<Map<String, dynamic>> updateVisitStatus(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.post('$_updateEndpoint/$id', body: data);
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getVisits({Map<String, dynamic>? query}) async {
    final response = await _apiClient.get(_createEndpoint, queryParams: query);
    final data = response['data'] as List<dynamic>?;
    return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }
}








