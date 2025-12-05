import '../core/result.dart';
import '../entity/permission_entity.dart';

/// Repository interface for permission operations
abstract class PermissionRepository {
  /// Get user permissions
  Future<Result<PermissionEntity>> getUserPermissions();

  /// Sync user permissions from remote to local
  Future<Result<void>> syncUserPermissions();

  /// Get user permissions from local storage
  Future<Result<PermissionEntity?>> getLocalUserPermissions();

  /// Check if user has a specific permission
  Future<Result<bool>> hasPermission(String permission);
}












