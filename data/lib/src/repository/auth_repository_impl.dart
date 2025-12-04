import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/auth_local_data_source.dart';
import '../data_source/remote/auth_remote_data_source.dart';
import '../mapper/auth_token_mapper.dart';
import '../mapper/user_mapper.dart';

/// Implementation of [AuthRepository]
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final AuthTokenMapper _tokenMapper;
  final UserMapper _userMapper;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    AuthTokenMapper tokenMapper = const AuthTokenMapper(),
    UserMapper userMapper = const UserMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
        _tokenMapper = tokenMapper,
        _userMapper = userMapper;

  @override
  Future<Result<AuthTokenEntity>> login({
    required String username,
    required String password,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

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
      final tokenModel = await _localDataSource.getToken();
      if (tokenModel == null) {
        return const Error(AuthFailure(message: 'No token found'));
      }

      if (!await _networkInfo.isConnected) {
        // Try to get cached user
        final cachedUser = await _localDataSource.getCachedUser();
        if (cachedUser != null) {
          return Success(_userMapper.toEntity(cachedUser));
        }
        return const Error(NetworkFailure());
      }

      final userModel =
          await _remoteDataSource.getCurrentUser(tokenModel.accessToken);

      // Cache user
      await _localDataSource.cacheUser(userModel);

      return Success(_userMapper.toEntity(userModel));
    } catch (e) {
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
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final tokenModel = await _remoteDataSource.refreshToken(refreshToken);
      final tokenEntity = _tokenMapper.toEntity(tokenModel);

      // Save new token
      await _localDataSource.saveToken(tokenModel);

      return Success(tokenEntity);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }
}









