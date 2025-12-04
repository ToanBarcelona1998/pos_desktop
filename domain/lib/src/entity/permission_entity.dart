import '../core/entity.dart';

/// User permission entity
class PermissionEntity extends Entity {
  final List<String> permissions;

  const PermissionEntity({
    required this.permissions,
  });

  bool hasPermission(String permission) {
    return permissions.contains(permission) || permissions.contains('admin');
  }

  bool hasAnyPermission(List<String> requiredPermissions) {
    if (permissions.contains('admin')) return true;
    return requiredPermissions.any((p) => permissions.contains(p));
  }

  bool hasAllPermissions(List<String> requiredPermissions) {
    if (permissions.contains('admin')) return true;
    return requiredPermissions.every((p) => permissions.contains(p));
  }

  @override
  List<Object?> get props => [permissions];
}










