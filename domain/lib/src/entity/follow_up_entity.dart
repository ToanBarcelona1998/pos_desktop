import '../core/entity.dart';

/// Follow up entity representing CRM follow up
class FollowUpEntity extends Entity {
  final int? id;
  final int contactId;
  final String? title;
  final String? status;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? description;
  final int? userId;
  final int? categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FollowUpEntity({
    this.id,
    required this.contactId,
    this.title,
    this.status,
    this.startDateTime,
    this.endDateTime,
    this.description,
    this.userId,
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        contactId,
        title,
        status,
        startDateTime,
        endDateTime,
        description,
        userId,
        categoryId,
        createdAt,
        updatedAt,
      ];
}

/// Follow up category entity
class FollowUpCategoryEntity extends Entity {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FollowUpCategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        createdAt,
        updatedAt,
      ];
}











