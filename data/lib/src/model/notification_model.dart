import 'base_model.dart';

/// DTO for notification data
class NotificationModel extends BaseModel {
  final String id;
  final String? type;
  final String? notifiableType;
  final int? notifiableId;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String? createdAt;
  final String? updatedAt;

  const NotificationModel({
    required this.id,
    this.type,
    this.notifiableType,
    this.notifiableId,
    this.data,
    this.readAt,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String?,
      notifiableType: json['notifiable_type'] as String?,
      notifiableId: json['notifiable_id'] as int?,
      data: json['data'] as Map<String, dynamic>?,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (type != null) 'type': type,
      if (notifiableType != null) 'notifiable_type': notifiableType,
      if (notifiableId != null) 'notifiable_id': notifiableId,
      if (data != null) 'data': data,
      if (readAt != null) 'read_at': readAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  /// Gets message from data
  String? get message {
    if (data == null) return null;
    return data!['msg'] as String? ?? data!['message'] as String?;
  }

  /// Checks if notification is read
  bool get isRead => readAt != null;
}







