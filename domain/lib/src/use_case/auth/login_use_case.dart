import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/auth_token_entity.dart';
import '../../repository/auth_repository.dart';

class LoginParams {
  final String username;
  final String password;

  const LoginParams({
    required this.username,
    required this.password,
  });
}

/// Use case for user login
class LoginUseCase implements UseCase<AuthTokenEntity, LoginParams> {
  final AuthRepository _authRepository;

  const LoginUseCase(this._authRepository);

  @override
  Future<Result<AuthTokenEntity>> call(LoginParams params) async {
    return await _authRepository.login(
      username: params.username,
      password: params.password,
    );
  }
}






