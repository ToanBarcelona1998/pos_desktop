import '../core/entity.dart';

final class NotificationEntity extends Entity {
  final String id;
  final String? type;
  final String? notifiableType;
  final int? notifiableId;
  final String? message;
  final bool isRead;
  final DateTime? createdAt;
  final DateTime? readAt;

  const NotificationEntity({
    required this.id,
    this.type,
    this.notifiableType,
    this.notifiableId,
    this.message,
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        notifiableId,
        isRead,
        createdAt,
      ];

  NotificationEntity copyWith({
    String? id,
    String? type,
    String? notifiableType,
    int? notifiableId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      type: type ?? this.type,
      notifiableType: notifiableType ?? this.notifiableType,
      notifiableId: notifiableId ?? this.notifiableId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}








