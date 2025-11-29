import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/notification_remote_data_source.dart';
import '../model/notification_model.dart';

/// Implementation of [NotificationRepository]
class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const NotificationRepositoryImpl({
    required NotificationRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<NotificationEntity>>> getNotifications() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final notifications = await _remoteDataSource.getNotifications();
      final entities = notifications.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    final result = await getNotifications();
    return result.fold(
      onSuccess: (notifications) {
        final unreadCount = notifications.where((n) => !n.isRead).length;
        return Success(unreadCount);
      },
      onError: (failure) => Error(failure),
    );
  }

  @override
  Future<Result<void>> markAsRead(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.markAsRead(id);
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> markAllAsRead() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final result = await getNotifications();
      return result.fold(
        onSuccess: (notifications) async {
          for (final notification in notifications.where((n) => !n.isRead)) {
            await _remoteDataSource.markAsRead(notification.id);
          }
          return const Success(null);
        },
        onError: (failure) => Error(failure),
      );
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteNotification(String id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      // Delete implementation - depends on API support
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  NotificationEntity _mapToEntity(NotificationModel model) {
    return NotificationEntity(
      id: model.id,
      type: model.type,
      notifiableType: model.notifiableType,
      notifiableId: model.notifiableId,
      message: model.message,
      isRead: model.isRead,
      createdAt: model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      readAt: model.readAt != null ? DateTime.tryParse(model.readAt!) : null,
    );
  }
}
