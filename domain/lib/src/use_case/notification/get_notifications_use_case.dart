import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/notification_entity.dart';
import '../../repository/notification_repository.dart';

/// Use case for getting notifications
class GetNotificationsUseCase implements UseCaseNoParams<List<NotificationEntity>> {
  final NotificationRepository _repository;

  const GetNotificationsUseCase(this._repository);

  @override
  Future<Result<List<NotificationEntity>>> call() async {
    return await _repository.getNotifications();
  }
}

/// Use case for getting unread notification count
class GetUnreadCountUseCase implements UseCaseNoParams<int> {
  final NotificationRepository _repository;

  const GetUnreadCountUseCase(this._repository);

  @override
  Future<Result<int>> call() async {
    return await _repository.getUnreadCount();
  }
}

/// Use case for marking notification as read
class MarkNotificationAsReadUseCase implements UseCase<void, String> {
  final NotificationRepository _repository;

  const MarkNotificationAsReadUseCase(this._repository);

  @override
  Future<Result<void>> call(String id) async {
    return await _repository.markAsRead(id);
  }
}
