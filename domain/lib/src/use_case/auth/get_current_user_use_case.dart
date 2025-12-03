import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/user_entity.dart';
import '../../repository/auth_repository.dart';

/// Use case for getting current logged in user
class GetCurrentUserUseCase implements UseCaseNoParams<UserEntity> {
  final AuthRepository _authRepository;

  const GetCurrentUserUseCase(this._authRepository);

  @override
  Future<Result<UserEntity>> call() async {
    return await _authRepository.getCurrentUser();
  }
}








