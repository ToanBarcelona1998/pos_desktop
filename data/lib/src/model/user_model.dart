import 'base_model.dart';

/// DTO for user data
class UserModel extends BaseModel {
  final int id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? surname;
  final bool? isAdmin;
  final List<dynamic>? allPermissions;
  final int? businessId;
  final int? roleId;
  final String? roleName;
  final String? userType;
  final String? language;
  final String? status;
  final String? contactNumber;
  final String? maxSalesDiscountPercent;

  const UserModel({
    required this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.surname,
    this.isAdmin,
    this.allPermissions,
    this.businessId,
    this.roleId,
    this.roleName,
    this.userType,
    this.language,
    this.status,
    this.contactNumber,
    this.maxSalesDiscountPercent,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      username: json['username'] as String?,
      email: json['email'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      surname: json['surname'] as String?,
      isAdmin: json['is_admin'] as bool? ?? (json['user_type'] == 'admin'),
      allPermissions: json['all_permissions'] as List<dynamic>?,
      businessId: int.tryParse(json['business_id']?.toString() ?? ''),
      roleId: int.tryParse(json['role_id'] ?? ''),
      roleName: json['role_name'] as String?,
      userType: json['user_type'] as String?,
      language: json['language'] as String?,
      status: json['status'] as String?,
      contactNumber: json['contact_number'] as String?,
      maxSalesDiscountPercent: json['max_sales_discount_percent'] as String?,
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
      if (surname != null) 'surname': surname,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (allPermissions != null) 'all_permissions': allPermissions,
      if (businessId != null) 'business_id': businessId,
      if (roleId != null) 'role_id': roleId,
      if (roleName != null) 'role_name': roleName,
      if (userType != null) 'user_type': userType,
      if (language != null) 'language': language,
      if (status != null) 'status': status,
      if (contactNumber != null) 'contact_number': contactNumber,
      if (maxSalesDiscountPercent != null)
        'max_sales_discount_percent': maxSalesDiscountPercent,
    };
  }
}








