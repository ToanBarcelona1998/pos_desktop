import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../repository/auth_repository.dart';

/// Use case for user logout
class LogoutUseCase implements UseCaseNoParams<void> {
  final AuthRepository _authRepository;

  const LogoutUseCase(this._authRepository);

  @override
  Future<Result<void>> call() async {
    return await _authRepository.logout();
  }
}

