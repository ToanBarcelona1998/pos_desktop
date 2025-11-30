import '../../core/api_client.dart';

/// Remote data source for follow up operations
abstract class FollowUpRemoteDataSource {
  /// Get follow up by ID
  Future<Map<String, dynamic>> getFollowUpById(int id);

  /// Get follow ups
  Future<List<Map<String, dynamic>>> getFollowUps({Map<String, dynamic>? query});

  /// Create a follow up
  Future<Map<String, dynamic>> createFollowUp(Map<String, dynamic> data);

  /// Update a follow up
  Future<Map<String, dynamic>> updateFollowUp(int id, Map<String, dynamic> data);

  /// Get follow up categories
  Future<List<Map<String, dynamic>>> getFollowUpCategories();

  /// Sync call log
  Future<bool> syncCallLog(Map<String, dynamic> data);
}

/// Implementation of [FollowUpRemoteDataSource]
class FollowUpRemoteDataSourceImpl implements FollowUpRemoteDataSource {
  final ApiClient _apiClient;
  final String _followUpEndpoint;
  final String _callLogEndpoint;
  final String _categoriesEndpoint;

  const FollowUpRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String followUpEndpoint,
    required String callLogEndpoint,
    required String categoriesEndpoint,
  })  : _apiClient = apiClient,
        _followUpEndpoint = followUpEndpoint,
        _callLogEndpoint = callLogEndpoint,
        _categoriesEndpoint = categoriesEndpoint;

  @override
  Future<Map<String, dynamic>> getFollowUpById(int id) async {
    final response = await _apiClient.get('$_followUpEndpoint/$id');
    final data = response['data'] as List<dynamic>?;
    return data?.first as Map<String, dynamic>? ?? {};
  }

  @override
  Future<List<Map<String, dynamic>>> getFollowUps({Map<String, dynamic>? query}) async {
    final response = await _apiClient.get(_followUpEndpoint, queryParams: query);
    final data = response['data'] as List<dynamic>?;
    return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }

  @override
  Future<Map<String, dynamic>> createFollowUp(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_followUpEndpoint, body: data);
    return response;
  }

  @override
  Future<Map<String, dynamic>> updateFollowUp(int id, Map<String, dynamic> data) async {
    final response = await _apiClient.put('$_followUpEndpoint/$id', body: data);
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getFollowUpCategories() async {
    final response = await _apiClient.get(_categoriesEndpoint);
    final data = response['data'] as List<dynamic>?;
    return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }

  @override
  Future<bool> syncCallLog(Map<String, dynamic> data) async {
    try {
      await _apiClient.post(_callLogEndpoint, body: data);
      return true;
    } catch (_) {
      return false;
    }
  }
}





