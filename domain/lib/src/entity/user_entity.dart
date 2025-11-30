import '../core/entity.dart';

final class UserEntity extends Entity {
  final int id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool isAdmin;
  final List<String> permissions;

  const UserEntity({
    required this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.isAdmin = false,
    this.permissions = const [],
  });

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        firstName,
        lastName,
        isAdmin,
        permissions,
      ];

  UserEntity copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    bool? isAdmin,
    List<String>? permissions,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      isAdmin: isAdmin ?? this.isAdmin,
      permissions: permissions ?? this.permissions,
    );
  }

  String get fullName {
    final parts = [firstName, lastName]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    return parts.isEmpty ? (username ?? '') : parts.join(' ');
  }

  bool hasPermission(String permission) {
    if (isAdmin) return true;
    return permissions.contains(permission) || permissions.contains('all');
  }
}





