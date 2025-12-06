import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/attendance_entity.dart';
import '../../repository/attendance_repository.dart';

/// Parameters for clock out use case
class ClockOutParams {
  final int userId;
  final double latitude;
  final double longitude;
  final String? note;
  final String? ipAddress;

  const ClockOutParams({
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.note,
    this.ipAddress,
  });
}

/// Use case for clocking out
class ClockOutUseCase implements UseCase<AttendanceEntity, ClockOutParams> {
  final AttendanceRepository _repository;

  const ClockOutUseCase(this._repository);

  @override
  Future<Result<AttendanceEntity>> call(ClockOutParams params) async {
    return await _repository.clockOut(
      userId: params.userId,
      latitude: params.latitude,
      longitude: params.longitude,
      note: params.note,
      ipAddress: params.ipAddress,
    );
  }
}














