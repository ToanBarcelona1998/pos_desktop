import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/brand_remote_data_source.dart';
import '../mapper/brand_mapper.dart';
import '../model/brand_model.dart';

/// Implementation of [BrandRepository]
/// Prioritizes local data for offline-first approach
class BrandRepositoryImpl implements BrandRepository {
  final BrandRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final BrandMapper _mapper;

  const BrandRepositoryImpl({
    required BrandRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    BrandMapper mapper = const BrandMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _mapper = mapper;

  @override
  Future<Result<List<BrandEntity>>> getBrands() async {
    // Always try local first (offline-first)
    final localResult = await getLocalBrands();
    
    return localResult.fold(
      onSuccess: (localBrands) async {
        // If we have local data, return it immediately
        if (localBrands.isNotEmpty) {
          // If online, sync in background for next time
          if (await _networkInfo.isConnected) {
            _syncBrandsInBackground();
          }
          return Success(localBrands);
        }
        
        // No local data - try remote if online
        if (await _networkInfo.isConnected) {
          try {
            final brandModels = await _remoteDataSource.getBrands();
            final brandEntities = _mapper.toEntityList(brandModels);
            
            // Save to local
            await syncBrands();
            
            return Success(brandEntities);
          } catch (e) {
            return Error(ExceptionHandler.handleException(e));
          }
        }
        
        // Offline and no local data
        return const Success([]);
      },
      onError: (failure) async {
        // Local fetch failed - try remote if online
        if (await _networkInfo.isConnected) {
          try {
            final brandModels = await _remoteDataSource.getBrands();
            final brandEntities = _mapper.toEntityList(brandModels);
            
            // Save to local
            await syncBrands();
            
            return Success(brandEntities);
          } catch (e) {
            return Error(ExceptionHandler.handleException(e));
          }
        }
        
        return Error(failure);
      },
    );
  }

  @override
  Future<Result<BrandEntity>> getBrandById(int id) async {
    final result = await getBrands();
    return result.fold(
      onSuccess: (brands) {
        final brand = brands.where((b) => b.id == id).firstOrNull;
        if (brand == null) {
          return const Error(NotFoundFailure(message: 'Brand not found'));
        }
        return Success(brand);
      },
      onError: (failure) => Error(failure),
    );
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
      final brandEntity = _mapper.toEntity(brandModel);
      
      // Sync brands to update local cache
      await syncBrands();
      
      return Success(brandEntity);
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
      final brandEntity = _mapper.toEntity(brandModel);
      
      // Sync brands to update local cache
      await syncBrands();
      
      return Success(brandEntity);
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
      
      // Sync brands to update local cache
      await syncBrands();
      
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<BrandEntity>>> searchBrands(String query) async {
    final result = await getBrands();
    return result.fold(
      onSuccess: (brands) {
        final queryLower = query.toLowerCase();
        final filteredBrands = brands.where((brand) {
          return brand.name.toLowerCase().contains(queryLower) ||
              (brand.description?.toLowerCase().contains(queryLower) ?? false);
        }).toList();
        return Success(filteredBrands);
      },
      onError: (failure) => Error(failure),
    );
  }

  /// Get brands from local cache
  Future<Result<List<BrandEntity>>> getLocalBrands() async {
    try {
      final data = await _localDataSource.get('brand');
      if (data == null) {
        return const Success([]);
      }

      final List<dynamic> brandList = data is String ? jsonDecode(data) : data;
      final brandModels = brandList
          .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
          .toList();
      final entities = _mapper.toEntityList(brandModels);
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  /// Sync brands in background without blocking
  void _syncBrandsInBackground() {
    syncBrands().catchError((e) {
      print('Background brand sync error: $e');
    });
  }

  /// Sync brands from remote to local
  Future<Result<void>> syncBrands() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final brands = await _remoteDataSource.getBrands();
      final brandsJson = brands.map((b) => b.toJson()).toList();
      await _localDataSource.insert('brand', jsonEncode(brandsJson));
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }
}
