import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/field_force_remote_data_source.dart';

/// Implementation of [FieldForceRepository]
class FieldForceRepositoryImpl implements FieldForceRepository {
  final FieldForceRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const FieldForceRepositoryImpl({
    required FieldForceRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<FieldForceVisitEntity>> createVisit({
    required int contactId,
    required DateTime visitDate,
    String? visitNote,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'contact_id': contactId,
        'visit_on': visitDate.toIso8601String().split('T')[0],
        if (visitNote != null) 'visit_note': visitNote,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (address != null) 'address': address,
      };

      final response = await _remoteDataSource.createVisit(data);
      return Success(_mapToEntity(response));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<FieldForceVisitEntity>> updateVisitStatus({
    required int visitId,
    required String status,
    String? note,
    DateTime? checkOutTime,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'status': status,
        if (note != null) 'note': note,
        if (checkOutTime != null) 'check_out_time': checkOutTime.toIso8601String(),
      };

      final response = await _remoteDataSource.updateVisitStatus(visitId, data);
      return Success(_mapToEntity(response));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<FieldForceVisitEntity>>> getVisits({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final query = <String, dynamic>{};
      if (userId != null) query['user_id'] = userId;
      if (startDate != null) query['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) query['end_date'] = endDate.toIso8601String().split('T')[0];
      if (status != null) query['status'] = status;

      final visits = await _remoteDataSource.getVisits(query: query);
      final entities = visits.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  FieldForceVisitEntity _mapToEntity(Map<String, dynamic> json) {
    return FieldForceVisitEntity(
      id: json['id'] as int?,
      contactId: json['contact_id'] as int,
      userId: json['user_id'] as int? ?? 0,
      visitDate: DateTime.tryParse(json['visit_on']?.toString() ?? '') ?? DateTime.now(),
      visitNote: json['visit_note'] as String?,
      visitStatus: json['status'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      checkInTime: json['check_in_time'] != null
          ? DateTime.tryParse(json['check_in_time'].toString())
          : null,
      checkOutTime: json['check_out_time'] != null
          ? DateTime.tryParse(json['check_out_time'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}




