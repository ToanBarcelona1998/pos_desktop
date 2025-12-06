import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/permission_remote_data_source.dart';

/// Implementation of [PermissionRepository]
class PermissionRepositoryImpl implements PermissionRepository {
  final PermissionRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;

  const PermissionRepositoryImpl({
    required PermissionRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Result<PermissionEntity>> getUserPermissions() async {
    try {
      final permissions = await _remoteDataSource.getUserPermissions();
      return Success(PermissionEntity(permissions: permissions));
    } catch (e) {
      Logger.logE('Failed to get user permissions from server, trying local', e);
      final localResult = await getLocalUserPermissions();
      return localResult.fold(
        onSuccess: (permission) {
          if (permission == null) {
            return Error(ExceptionHandler.handleException(e));
          }
          return Success(permission);
        },
        onError: (failure) => Error(failure),
      );
    }
  }

  @override
  Future<Result<void>> syncUserPermissions() async {
    try {
      final permissions = await _remoteDataSource.getUserPermissions();
      await _localDataSource.insert('user_permissions', jsonEncode(permissions));
      return const Success(null);
    } catch (e) {
      Logger.logE('Error syncing user permissions', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<PermissionEntity?>> getLocalUserPermissions() async {
    try {
      final data = await _localDataSource.get('user_permissions');
      if (data == null) {
        return const Success(null);
      }

      final List<dynamic> permissionList = data is String ? jsonDecode(data) : data;
      final permissions = permissionList.map((e) => e.toString()).toList();
      return Success(PermissionEntity(permissions: permissions));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<bool>> hasPermission(String permission) async {
    final result = await getUserPermissions();
    return result.fold(
      onSuccess: (entity) => Success(entity.hasPermission(permission)),
      onError: (failure) => Error(failure),
    );
  }
}












