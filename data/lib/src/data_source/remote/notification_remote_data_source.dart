import '../../core/api_client.dart';
import '../../model/notification_model.dart';

/// Remote data source for notification operations
abstract class NotificationRemoteDataSource {
  /// Get all notifications
  Future<List<NotificationModel>> getNotifications();

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);
}

/// Implementation of [NotificationRemoteDataSource]
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient _apiClient;
  final String _endpoint;

  const NotificationRemoteDataSourceImpl({
    required ApiClient apiClient,
    required String endpoint,
  })  : _apiClient = apiClient,
        _endpoint = endpoint;

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _apiClient.get(_endpoint);
    final data = response['data'] as List<dynamic>? ?? [];
    return data
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _apiClient.post('$_endpoint/$notificationId/read');
  }
}






