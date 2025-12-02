import '../core/result.dart';
import '../entity/unit_entity.dart';

/// Repository interface for unit operations
abstract class UnitRepository {
  /// Get all units
  Future<Result<List<UnitEntity>>> getUnits();

  /// Get a unit by ID
  Future<Result<UnitEntity>> getUnitById(int id);

  /// Create a new unit
  Future<Result<UnitEntity>> createUnit({
    required String actualName,
    required String shortName,
    bool allowDecimal = false,
  });

  /// Update an existing unit
  Future<Result<UnitEntity>> updateUnit({
    required int id,
    String? actualName,
    String? shortName,
    bool? allowDecimal,
  });

  /// Delete a unit
  Future<Result<void>> deleteUnit(int id);
}







