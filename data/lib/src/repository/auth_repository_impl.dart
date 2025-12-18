import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/local/auth_local_data_source.dart';
import '../data_source/remote/auth_remote_data_source.dart';
import '../mapper/auth_token_mapper.dart';
import '../mapper/user_mapper.dart';

/// Implementation of [AuthRepository]
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final AuthTokenMapper _tokenMapper;
  final UserMapper _userMapper;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    AuthTokenMapper tokenMapper = const AuthTokenMapper(),
    UserMapper userMapper = const UserMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _tokenMapper = tokenMapper,
        _userMapper = userMapper;

  @override
  Future<Result<AuthTokenEntity>> login({
    required String username,
    required String password,
  }) async {
    try {
      final tokenModel = await _remoteDataSource.login(
        username: username,
        password: password,
      );
      final tokenEntity = _tokenMapper.toEntity(tokenModel);

      // Save token locally
      await _localDataSource.saveToken(tokenModel);

      return Success(tokenEntity);
    } catch (e) {
      Logger.logE('Error during login', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _localDataSource.clearToken();
      await _localDataSource.clearCachedUser();
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    try {
      final cachedUser = await _localDataSource.getCachedUser();

      if(cachedUser != null){
        return Success(_userMapper.toEntity(cachedUser));
      }

      final tokenModel = await _localDataSource.getToken();
      if (tokenModel == null) {
        return const Error(AuthFailure(message: 'No token found'));
      }

      try {
        final userModel =
            await _remoteDataSource.getCurrentUser(tokenModel.accessToken);

        // Cache user
        await _localDataSource.cacheUser(userModel);

        return Success(_userMapper.toEntity(userModel));
      } catch (e) {
        // If server call fails, try cached user
        Logger.logE('Failed to get user from server, trying cached user', e);
        final cachedUser = await _localDataSource.getCachedUser();
        if (cachedUser != null) {
          return Success(_userMapper.toEntity(cachedUser));
        }
        return Error(ExceptionHandler.handleException(e));
      }
    } catch (e) {
      Logger.logE('Error getting current user', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<AuthTokenEntity>> getStoredToken() async {
    try {
      final tokenModel = await _localDataSource.getToken();
      if (tokenModel == null) {
        return const Error(AuthFailure(message: 'No token found'));
      }
      return Success(_tokenMapper.toEntity(tokenModel));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> saveToken(AuthTokenEntity token) async {
    try {
      final tokenModel = _tokenMapper.toModel(token);
      await _localDataSource.saveToken(tokenModel);
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> clearToken() async {
    try {
      await _localDataSource.clearToken();
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final tokenModel = await _localDataSource.getToken();
      return Success(tokenModel != null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<AuthTokenEntity>> refreshToken(String refreshToken) async {
    try {
      final tokenModel = await _remoteDataSource.refreshToken(refreshToken);
      final tokenEntity = _tokenMapper.toEntity(tokenModel);

      // Save new token
      await _localDataSource.saveToken(tokenModel);

      return Success(tokenEntity);
    } catch (e) {
      Logger.logE('Error refreshing token', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }
}












