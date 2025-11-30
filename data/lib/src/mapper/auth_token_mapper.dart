import 'package:domain/domain.dart';

import '../model/auth_token_model.dart';
import 'base_mapper.dart';

/// Mapper for AuthToken
class AuthTokenMapper extends Mapper<AuthTokenModel, AuthTokenEntity> {
  const AuthTokenMapper();

  @override
  AuthTokenEntity toEntity(AuthTokenModel model) {
    return AuthTokenEntity(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
      tokenType: model.tokenType,
      expiresAt: model.expiresIn != null
          ? DateTime.now().add(Duration(seconds: model.expiresIn!))
          : null,
    );
  }

  @override
  AuthTokenModel toModel(AuthTokenEntity entity) {
    return AuthTokenModel(
      accessToken: entity.accessToken,
      refreshToken: entity.refreshToken,
      tokenType: entity.tokenType,
      expiresIn: entity.expiresAt?.difference(DateTime.now()).inSeconds,
    );
  }
}




