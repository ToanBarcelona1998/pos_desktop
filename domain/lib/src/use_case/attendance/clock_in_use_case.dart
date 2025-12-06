import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/attendance_entity.dart';
import '../../repository/attendance_repository.dart';

/// Parameters for clock in use case
class ClockInParams {
  final int userId;
  final double latitude;
  final double longitude;
  final String? note;
  final String? ipAddress;

  const ClockInParams({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.note,
    this.ipAddress,
  });
}

/// Use case for clocking in
class ClockInUseCase implements UseCase<AttendanceEntity, ClockInParams> {
  final AttendanceRepository _repository;

  const ClockInUseCase(this._repository);

  @override
  Future<Result<AttendanceEntity>> call(ClockInParams params) async {
    return await _repository.clockIn(
      userId: params.userId,
      latitude: params.latitude,
      longitude: params.longitude,
      note: params.note,
      ipAddress: params.ipAddress,
    );
  }
}














