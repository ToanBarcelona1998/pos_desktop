import '../core/result.dart';
import '../entity/attendance_entity.dart';

/// Repository interface for attendance operations
abstract class AttendanceRepository {
  /// Clock in
  Future<Result<AttendanceEntity>> clockIn({
    required int userId,
    required double latitude,
    required double longitude,
    String? note,
    String? ipAddress,
  });

  /// Clock out
  Future<Result<AttendanceEntity>> clockOut({
    required int userId,
    required double latitude,
    required double longitude,
    String? note,
    String? ipAddress,
  });

  /// Get attendance details for a user
  Future<Result<List<AttendanceEntity>>> getAttendanceDetails(int userId);

  /// Get today's attendance for a user
  Future<Result<AttendanceEntity?>> getTodayAttendance(int userId);
}






