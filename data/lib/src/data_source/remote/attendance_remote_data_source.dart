import '../../core/api_client.dart';

/// Remote data source for attendance operations
abstract class AttendanceRemoteDataSource {
  /// Clock in
  Future<Map<String, dynamic>> clockIn(Map<String, dynamic> data);

  /// Clock out
  Future<Map<String, dynamic>> clockOut(Map<String, dynamic> data);

  /// Get attendance details for a user
  Future<List<Map<String, dynamic>>> getAttendanceDetails(int userId);
}

/// Implementation of [AttendanceRemoteDataSource]
class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final ApiClient _apiClient;
  final String _checkInEndpoint;
  final String _checkOutEndpoint;
  final String _getAttendanceEndpoint;

  const AttendanceRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String checkInEndpoint,
    required String checkOutEndpoint,
    required String getAttendanceEndpoint,
  })  : _apiClient = apiClient,
        _checkInEndpoint = checkInEndpoint,
        _checkOutEndpoint = checkOutEndpoint,
        _getAttendanceEndpoint = getAttendanceEndpoint;

  @override
  Future<Map<String, dynamic>> clockIn(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_checkInEndpoint, body: data);
    return response;
  }

  @override
  Future<Map<String, dynamic>> clockOut(Map<String, dynamic> data) async {
    final response = await _apiClient.post(_checkOutEndpoint, body: data);
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getAttendanceDetails(int userId) async {
    final response = await _apiClient.get('$_getAttendanceEndpoint$userId');
    final data = response['data'] as List<dynamic>?;
    return data?.map((e) => e as Map<String, dynamic>).toList() ?? [];
  }
}

