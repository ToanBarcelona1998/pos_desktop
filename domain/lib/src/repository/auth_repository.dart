import '../core/result.dart';
import '../entity/auth_token_entity.dart';
import '../entity/user_entity.dart';

/// Abstract repository for authentication operations.
/// This interface should be implemented in the data layer.
abstract class AuthRepository {
  /// Logs in with username and password.
  /// Returns [AuthTokenEntity] on success.
  Future<Result<AuthTokenEntity>> login({
    required String username,
    required String password,
  });

  /// Logs out the current user.
  Future<Result<void>> logout();

  /// Gets the current logged in user.
  Future<Result<UserEntity>> getCurrentUser();

  /// Gets the stored authentication token.
  Future<Result<AuthTokenEntity>> getStoredToken();

  /// Saves the authentication token.
  Future<Result<void>> saveToken(AuthTokenEntity token);

  /// Clears the stored authentication token.
  Future<Result<void>> clearToken();

  /// Checks if user is authenticated.
  Future<Result<bool>> isAuthenticated();

  /// Refreshes the authentication token.
  Future<Result<AuthTokenEntity>> refreshToken(String refreshToken);
}










