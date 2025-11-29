import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/brand_remote_data_source.dart';
import '../mapper/brand_mapper.dart';

/// Implementation of [BrandRepository]
class BrandRepositoryImpl implements BrandRepository {
  final BrandRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final BrandMapper _mapper;

  const BrandRepositoryImpl({
    required BrandRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    BrandMapper mapper = const BrandMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _mapper = mapper;

  @override
  Future<Result<List<BrandEntity>>> getBrands() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final brandModels = await _remoteDataSource.getBrands();
      final brandEntities = _mapper.toEntityList(brandModels);
      return Success(brandEntities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<BrandEntity>> getBrandById(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final brandModel = await _remoteDataSource.getBrandById(id);
      return Success(_mapper.toEntity(brandModel));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<BrandEntity>> createBrand({
    required String name,
    String? description,
    bool? useForRepair,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = {
        'name': name,
        if (description != null) 'description': description,
        if (useForRepair != null) 'use_for_repair': useForRepair ? 1 : 0,
      };
      final brandModel = await _remoteDataSource.createBrand(data);
      return Success(_mapper.toEntity(brandModel));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<BrandEntity>> updateBrand({
    required int id,
    String? name,
    String? description,
    bool? useForRepair,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (useForRepair != null) data['use_for_repair'] = useForRepair ? 1 : 0;

      final brandModel = await _remoteDataSource.updateBrand(id, data);
      return Success(_mapper.toEntity(brandModel));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteBrand(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.deleteBrand(id);
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<BrandEntity>>> searchBrands(String query) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final brandModels = await _remoteDataSource.getBrands();
      final brandEntities = _mapper.toEntityList(brandModels);

      // Filter by query
      final filteredBrands = brandEntities.where((brand) {
        final queryLower = query.toLowerCase();
        return brand.name.toLowerCase().contains(queryLower) ||
            (brand.description?.toLowerCase().contains(queryLower) ?? false);
      }).toList();

      return Success(filteredBrands);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }
}

