import '../core/entity.dart';

/// Attendance entity representing user attendance data
class AttendanceEntity extends Entity {
  final int? id;
  final int userId;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final String? clockInNote;
  final String? clockOutNote;
  final double? latitude;
  final double? longitude;
  final String? ipAddress;

  const AttendanceEntity({
    this.id,
    required this.userId,
    this.clockInTime,
    this.clockOutTime,
    this.clockInNote,
    this.clockOutNote,
    this.latitude,
    this.longitude,
    this.ipAddress,
  });

  bool get isClockedIn => clockInTime != null && clockOutTime == null;

  @override
  List<Object?> get props => [
        id,
        userId,
        clockInTime,
        clockOutTime,
        clockInNote,
        clockOutNote,
        latitude,
        longitude,
        ipAddress,
      ];
}




