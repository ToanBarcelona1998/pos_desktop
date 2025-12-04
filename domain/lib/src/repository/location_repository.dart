import '../core/result.dart';
import '../entity/location_entity.dart';

/// Repository interface for location operations
abstract class LocationRepository {
  /// Get all business locations
  Future<Result<List<LocationEntity>>> getLocations();

  /// Get location by ID
  Future<Result<LocationEntity>> getLocationById(int id);

  /// Sync locations from remote to local
  Future<Result<void>> syncLocations();

  /// Get locations from local storage
  Future<Result<List<LocationEntity>>> getLocalLocations();
}










