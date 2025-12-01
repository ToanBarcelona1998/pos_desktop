import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/attendance_entity.dart';
import '../../repository/attendance_repository.dart';

/// Use case for getting attendance details
class GetAttendanceUseCase implements UseCase<List<AttendanceEntity>, int> {
  final AttendanceRepository _repository;

  const GetAttendanceUseCase(this._repository);

  @override
  Future<Result<List<AttendanceEntity>>> call(int userId) async {
    return await _repository.getAttendanceDetails(userId);
  }
}






