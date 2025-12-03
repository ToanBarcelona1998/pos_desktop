import 'package:domain/domain.dart';

import '../model/user_model.dart';
import 'base_mapper.dart';

/// Mapper for User
class UserMapper extends ReadOnlyMapper<UserModel, UserEntity> {
  const UserMapper();

  @override
  UserEntity toEntity(UserModel model) {
    return UserEntity(
      id: model.id,
      username: model.username,
      email: model.email,
      firstName: model.firstName,
      lastName: model.lastName,
      surname: model.surname,
      isAdmin: model.isAdmin ?? false,
      permissions: model.allPermissions
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      businessId: model.businessId,
      roleId: model.roleId,
      roleName: model.roleName,
      userType: model.userType,
      language: model.language,
      status: model.status,
      contactNumber: model.contactNumber,
      maxSalesDiscountPercent: model.maxSalesDiscountPercent != null
          ? double.tryParse(model.maxSalesDiscountPercent!)
          : null,
    );
  }
}








