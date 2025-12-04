import '../core/entity.dart';

/// Field force visit entity
class FieldForceVisitEntity extends Entity {
  final int? id;
  final int contactId;
  final int userId;
  final DateTime visitDate;
  final String? visitNote;
  final String? visitStatus;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FieldForceVisitEntity({
    this.id,
    required this.contactId,
    required this.userId,
    required this.visitDate,
    this.visitNote,
    this.visitStatus,
    this.latitude,
    this.longitude,
    this.address,
    this.checkInTime,
    this.checkOutTime,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        contactId,
        userId,
        visitDate,
        visitNote,
        visitStatus,
        latitude,
        longitude,
        address,
        checkInTime,
        checkOutTime,
        createdAt,
        updatedAt,
      ];
}









