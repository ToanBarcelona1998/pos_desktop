import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/location_entity.dart';
import '../../repository/location_repository.dart';

/// Use case for getting all locations
class GetLocationsUseCase implements UseCaseNoParams<List<LocationEntity>> {
  final LocationRepository _repository;

  const GetLocationsUseCase(this._repository);

  @override
  Future<Result<List<LocationEntity>>> call() async {
    return await _repository.getLocations();
  }
}







