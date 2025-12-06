import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/remote/follow_up_remote_data_source.dart';

/// Implementation of [FollowUpRepository]
class FollowUpRepositoryImpl implements FollowUpRepository {
  final FollowUpRemoteDataSource _remoteDataSource;

  const FollowUpRepositoryImpl({
    required FollowUpRemoteDataSource remoteDataSource,
  })  : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<FollowUpEntity>> getFollowUpById(int id) async {
    try {
      final response = await _remoteDataSource.getFollowUpById(id);
      if (response.isEmpty) {
        return const Error(NotFoundFailure(message: 'Follow up not found'));
      }
      return Success(_mapToEntity(response));
    } catch (e) {
      Logger.logE('Error getting follow up by id', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<FollowUpEntity>>> getFollowUps({
    int? contactId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (contactId != null) query['contact_id'] = contactId;
      if (status != null) query['status'] = status;
      if (startDate != null) query['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) query['end_date'] = endDate.toIso8601String().split('T')[0];

      final followUps = await _remoteDataSource.getFollowUps(query: query);
      final entities = followUps.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      Logger.logE('Error getting follow ups', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<FollowUpEntity>> createFollowUp({
    required int contactId,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? categoryId,
  }) async {
    try {
      final data = {
        'contact_id': contactId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (startDateTime != null) 'start_datetime': startDateTime.toIso8601String(),
        if (endDateTime != null) 'end_datetime': endDateTime.toIso8601String(),
        if (categoryId != null) 'followup_category_id': categoryId,
      };

      final response = await _remoteDataSource.createFollowUp(data);
      return Success(_mapToEntity(response));
    } catch (e) {
      Logger.logE('Error creating follow up', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<FollowUpEntity>> updateFollowUp({
    required int id,
    String? title,
    String? status,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? categoryId,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (status != null) data['status'] = status;
      if (description != null) data['description'] = description;
      if (startDateTime != null) data['start_datetime'] = startDateTime.toIso8601String();
      if (endDateTime != null) data['end_datetime'] = endDateTime.toIso8601String();
      if (categoryId != null) data['followup_category_id'] = categoryId;

      final response = await _remoteDataSource.updateFollowUp(id, data);
      return Success(_mapToEntity(response));
    } catch (e) {
      Logger.logE('Error updating follow up', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<FollowUpCategoryEntity>>> getFollowUpCategories() async {
    try {
      final categories = await _remoteDataSource.getFollowUpCategories();
      final entities = categories.map(_mapCategoryToEntity).toList();
      return Success(entities);
    } catch (e) {
      Logger.logE('Error getting follow up categories', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<bool>> syncCallLog({
    required int contactId,
    required DateTime callTime,
    required String callType,
    int? duration,
    String? note,
  }) async {
    try {
      final data = {
        'contact_id': contactId,
        'call_type': callType,
        'start_time': callTime.toIso8601String(),
        if (duration != null) 'duration': duration,
        if (note != null) 'call_log_note': note,
      };

      final success = await _remoteDataSource.syncCallLog(data);
      return Success(success);
    } catch (e) {
      Logger.logE('Error syncing call log', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  FollowUpEntity _mapToEntity(Map<String, dynamic> json) {
    return FollowUpEntity(
      id: json['id'] as int?,
      contactId: json['contact_id'] as int,
      title: json['title'] as String?,
      status: json['status'] as String?,
      startDateTime: json['start_datetime'] != null
          ? DateTime.tryParse(json['start_datetime'].toString())
          : null,
      endDateTime: json['end_datetime'] != null
          ? DateTime.tryParse(json['end_datetime'].toString())
          : null,
      description: json['description'] as String?,
      userId: json['created_by'] as int?,
      categoryId: json['followup_category_id'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  FollowUpCategoryEntity _mapCategoryToEntity(Map<String, dynamic> json) {
    return FollowUpCategoryEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}












