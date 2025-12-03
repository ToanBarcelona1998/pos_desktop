import '../../core/api_client.dart';

/// Remote data source for permission operations
abstract class PermissionRemoteDataSource {
  /// Get user permissions
  Future<List<String>> getUserPermissions();
}

/// Implementation of [PermissionRemoteDataSource]
class PermissionRemoteDataSourceImpl implements PermissionRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const PermissionRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<String>> getUserPermissions() async {
    final response = await _apiClient.get(_endpoint);
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null || !data.containsKey('all_permissions')) {
      return [];
    }
    final permissions = data['all_permissions'] as List<dynamic>?;
    return permissions?.map((e) => e.toString()).toList() ?? [];
  }
}








