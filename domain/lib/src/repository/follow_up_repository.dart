import '../core/result.dart';
import '../entity/follow_up_entity.dart';

/// Repository interface for follow up operations
abstract class FollowUpRepository {
  /// Get follow up by ID
  Future<Result<FollowUpEntity>> getFollowUpById(int id);

  /// Get follow ups for a contact
  Future<Result<List<FollowUpEntity>>> getFollowUps({
    int? contactId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Create a follow up
  Future<Result<FollowUpEntity>> createFollowUp({
    required int contactId,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? categoryId,
  });

  /// Update a follow up
  Future<Result<FollowUpEntity>> updateFollowUp({
    required int id,
    String? title,
    String? status,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    int? categoryId,
  });

  /// Get follow up categories
  Future<Result<List<FollowUpCategoryEntity>>> getFollowUpCategories();

  /// Sync call log
  Future<Result<bool>> syncCallLog({
    required int contactId,
    required DateTime callTime,
    required String callType,
    int? duration,
    String? note,
  });
}

