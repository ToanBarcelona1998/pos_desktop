import '../core/result.dart';
import '../entity/notification_entity.dart';

/// Abstract repository for notification operations.
abstract class NotificationRepository {
  /// Gets all notifications
  Future<Result<List<NotificationEntity>>> getNotifications();

  /// Gets unread notifications count
  Future<Result<int>> getUnreadCount();

  /// Marks a notification as read
  Future<Result<void>> markAsRead(String id);

  /// Marks all notifications as read
  Future<Result<void>> markAllAsRead();

  /// Deletes a notification
  Future<Result<void>> deleteNotification(String id);
}








