import '../core/entity.dart';

final class UserEntity extends Entity {
  final int id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? surname;
  final bool isAdmin;
  final List<String> permissions;
  final int? businessId;
  final int? roleId;
  final String? roleName;
  final String? userType;
  final String? language;
  final String? status;
  final String? contactNumber;
  final double? maxSalesDiscountPercent;

  const UserEntity({
    required this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.surname,
    this.isAdmin = false,
    this.permissions = const [],
    this.businessId,
    this.roleId,
    this.roleName,
    this.userType,
    this.language,
    this.status,
    this.contactNumber,
    this.maxSalesDiscountPercent,
  });

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        firstName,
        lastName,
        surname,
        isAdmin,
        permissions,
        businessId,
        roleId,
        roleName,
        userType,
        language,
        status,
        contactNumber,
        maxSalesDiscountPercent,
      ];

  UserEntity copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? surname,
    bool? isAdmin,
    List<String>? permissions,
    int? businessId,
    int? roleId,
    String? roleName,
    String? userType,
    String? language,
    String? status,
    String? contactNumber,
    double? maxSalesDiscountPercent,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      surname: surname ?? this.surname,
      isAdmin: isAdmin ?? this.isAdmin,
      permissions: permissions ?? this.permissions,
      businessId: businessId ?? this.businessId,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      userType: userType ?? this.userType,
      language: language ?? this.language,
      status: status ?? this.status,
      contactNumber: contactNumber ?? this.contactNumber,
      maxSalesDiscountPercent:
          maxSalesDiscountPercent ?? this.maxSalesDiscountPercent,
    );
  }

  String get fullName {
    final parts = [
      surname,
      firstName,
      lastName,
    ].where((p) => p != null && p.isNotEmpty).toList();
    return parts.isEmpty ? (username ?? '') : parts.join(' ');
  }

  bool hasPermission(String permission) {
    if (isAdmin) return true;
    return permissions.contains(permission) || permissions.contains('all');
  }

  bool get isActive => status == 'active';
}








