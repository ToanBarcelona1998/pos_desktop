import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/location_remote_data_source.dart';
import '../model/location_model.dart';

/// Implementation of [LocationRepository]
/// Prioritizes local data for offline-first approach
class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  const LocationRepositoryImpl({
    required LocationRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<LocationEntity>>> getLocations() async {
    // Always try local first (offline-first)
    final localResult = await getLocalLocations();
    
    return localResult.fold(
      onSuccess: (localLocations) async {
        // If we have local data, return it immediately
        if (localLocations.isNotEmpty) {
          // If online, sync in background for next time
          if (await _networkInfo.isConnected) {
            _syncLocationsInBackground();
          }
          return Success(localLocations);
        }
        
        // No local data - try remote if online
        if (await _networkInfo.isConnected) {
          try {
            final locations = await _remoteDataSource.getLocations();
            final entities = locations.map(_mapToEntity).toList();
            
            // Save to local
            await syncLocations();
            
            return Success(entities);
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
            final locations = await _remoteDataSource.getLocations();
            final entities = locations.map(_mapToEntity).toList();
            
            // Save to local
            await syncLocations();
            
            return Success(entities);
          } catch (e) {
            return Error(ExceptionHandler.handleException(e));
          }
        }
        
        return Error(failure);
      },
    );
  }

  @override
  Future<Result<LocationEntity>> getLocationById(int id) async {
    final result = await getLocations();
    return result.fold(
      onSuccess: (locations) {
        final location = locations.where((l) => l.id == id).firstOrNull;
        if (location == null) {
          return const Error(NotFoundFailure(message: 'Location not found'));
        }
        return Success(location);
      },
      onError: (failure) => Error(failure),
    );
  }

  /// Sync locations in background without blocking
  void _syncLocationsInBackground() {
    syncLocations().catchError((e) {
      print('Background location sync error: $e');
    });
  }

  @override
  Future<Result<void>> syncLocations() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final locations = await _remoteDataSource.getLocations();
      final locationsJson = locations.map((l) => l.toJson()).toList();
      await _localDataSource.insert('location', jsonEncode(locationsJson));

      // Store payment methods per location
      for (final location in locations) {
        if (location.paymentMethods != null && location.paymentMethods!.isNotEmpty) {
          await _localDataSource.insert(
            'payment_method',
            jsonEncode(location.paymentMethods),
            location.id,
          );
        }
      }
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<LocationEntity>>> getLocalLocations() async {
    try {
      final data = await _localDataSource.get('location');
      if (data == null) {
        return const Success([]);
      }

      final List<dynamic> locationList = data is String ? jsonDecode(data) : data;
      final entities = locationList
          .map((json) => LocationModel.fromJson(json as Map<String, dynamic>))
          .map(_mapToEntity)
          .toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  LocationEntity _mapToEntity(LocationModel model) {
    return LocationEntity(
      id: model.id,
      businessId: model.businessId,
      name: model.name,
      locationId: model.locationId,
      landmark: model.landmark,
      city: model.city,
      state: model.state,
      country: model.country,
      zipCode: model.zipCode,
      mobile: model.mobile,
      alternateNumber: model.alternateNumber,
      email: model.email,
      website: model.website,
      isActive: model.isActive == 1,
      paymentMethods: model.paymentMethods?.map((e) => e.toString()).toList() ?? [],
      createdAt: model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      updatedAt: model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null,
    );
  }
}
