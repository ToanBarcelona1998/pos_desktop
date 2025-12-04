import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/attendance_remote_data_source.dart';

/// Implementation of [AttendanceRepository]
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const AttendanceRepositoryImpl({
    required AttendanceRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<AttendanceEntity>> clockIn({
    required int userId,
    required double latitude,
    required double longitude,
    String? note,
    String? ipAddress,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'user_id': userId,
        'clock_in_latitude': latitude,
        'clock_in_longitude': longitude,
        if (note != null) 'clock_in_note': note,
        if (ipAddress != null) 'ip_address': ipAddress,
      };

      final response = await _remoteDataSource.clockIn(data);
      final entity = _mapToEntity(response);
      return Success(entity);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<AttendanceEntity>> clockOut({
    required int userId,
    required double latitude,
    required double longitude,
    String? note,
    String? ipAddress,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'user_id': userId,
        'clock_out_latitude': latitude,
        'clock_out_longitude': longitude,
        if (note != null) 'clock_out_note': note,
        if (ipAddress != null) 'ip_address': ipAddress,
      };

      final response = await _remoteDataSource.clockOut(data);
      final entity = _mapToEntity(response);
      return Success(entity);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<AttendanceEntity>>> getAttendanceDetails(int userId) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final response = await _remoteDataSource.getAttendanceDetails(userId);
      final entities = response.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<AttendanceEntity?>> getTodayAttendance(int userId) async {
    final result = await getAttendanceDetails(userId);
    return result.fold(
      onSuccess: (data) {
        final today = DateTime.now();
        final todayAttendance = data.where((a) {
          final clockIn = a.clockInTime;
          if (clockIn == null) return false;
          return clockIn.year == today.year &&
              clockIn.month == today.month &&
              clockIn.day == today.day;
        }).firstOrNull;
        return Success(todayAttendance);
      },
      onError: (failure) => Error(failure),
    );
  }

  AttendanceEntity _mapToEntity(Map<String, dynamic> json) {
    return AttendanceEntity(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      clockInTime: json['clock_in_time'] != null
          ? DateTime.tryParse(json['clock_in_time'].toString())
          : null,
      clockOutTime: json['clock_out_time'] != null
          ? DateTime.tryParse(json['clock_out_time'].toString())
          : null,
      clockInNote: json['clock_in_note'] as String?,
      clockOutNote: json['clock_out_note'] as String?,
      latitude: (json['clock_in_latitude'] as num?)?.toDouble(),
      longitude: (json['clock_in_longitude'] as num?)?.toDouble(),
      ipAddress: json['ip_address'] as String?,
    );
  }
}









