import 'base_model.dart';

/// DTO for user data
class UserModel extends BaseModel {
  final int id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final bool? isAdmin;
  final List<dynamic>? allPermissions;

  const UserModel({
    required this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.isAdmin,
    this.allPermissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String?,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      isAdmin: json['is_admin'] as bool?,
      allPermissions: json['all_permissions'] as List<dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (allPermissions != null) 'all_permissions': allPermissions,
    };
  }
}






