import '../core/result.dart';
import '../entity/field_force_entity.dart';

/// Repository interface for field force operations
abstract class FieldForceRepository {
  /// Create a new field force visit
  Future<Result<FieldForceVisitEntity>> createVisit({
    required int contactId,
    required DateTime visitDate,
    String? visitNote,
    double? latitude,
    double? longitude,
    String? address,
  });

  /// Update visit status
  Future<Result<FieldForceVisitEntity>> updateVisitStatus({
    required int visitId,
    required String status,
    String? note,
    DateTime? checkOutTime,
  });

  /// Get visits
  Future<Result<List<FieldForceVisitEntity>>> getVisits({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  });
}






