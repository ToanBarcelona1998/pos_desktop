import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/unit_remote_data_source.dart';
import '../model/unit_model.dart';

/// Implementation of [UnitRepository]
class UnitRepositoryImpl implements UnitRepository {
  final UnitRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const UnitRepositoryImpl({
    required UnitRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<UnitEntity>>> getUnits() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final units = await _remoteDataSource.getUnits();
      final entities = units.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<UnitEntity>> getUnitById(int id) async {
    final result = await getUnits();
    return result.fold(
      onSuccess: (units) {
        final unit = units.where((u) => u.id == id).firstOrNull;
        if (unit == null) {
          return const Error(NotFoundFailure(message: 'Unit not found'));
        }
        return Success(unit);
      },
      onError: (failure) => Error(failure),
    );
  }

  @override
  Future<Result<UnitEntity>> createUnit({
    required String actualName,
    required String shortName,
    bool allowDecimal = false,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'actual_name': actualName,
        'short_name': shortName,
        'allow_decimal': allowDecimal ? 1 : 0,
      };
      final unit = await _remoteDataSource.createUnit(data);
      return Success(_mapToEntity(unit));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<UnitEntity>> updateUnit({
    required int id,
    String? actualName,
    String? shortName,
    bool? allowDecimal,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = <String, dynamic>{};
      if (actualName != null) data['actual_name'] = actualName;
      if (shortName != null) data['short_name'] = shortName;
      if (allowDecimal != null) data['allow_decimal'] = allowDecimal ? 1 : 0;

      final unit = await _remoteDataSource.updateUnit(id, data);
      return Success(_mapToEntity(unit));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteUnit(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.deleteUnit(id);
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  UnitEntity _mapToEntity(UnitModel model) {
    return UnitEntity(
      id: model.id,
      businessId: model.businessId,
      actualName: model.actualName,
      shortName: model.shortName,
      allowDecimal: model.allowDecimal == 1,
      createdAt: model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      updatedAt: model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null,
    );
  }
}












