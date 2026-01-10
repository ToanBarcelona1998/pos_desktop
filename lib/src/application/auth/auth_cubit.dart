import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app_config/di.dart';
import 'auth_state.dart';

/// Cubit for managing authentication state globally
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final DatabaseManager _databaseManager;
  final SystemSyncService _syncService;

  AuthCubit({
    AuthRepository? authRepository,
    DatabaseManager? databaseManager,
    SystemSyncService? syncService,
  })  : _authRepository = authRepository ?? sl.get<AuthRepository>(),
        _databaseManager = databaseManager ?? sl.get<DatabaseManager>(),
        _syncService = syncService ?? sl.get<SystemSyncService>(),
        super(const AuthInitial());

  /// Checks if user is already authenticated
  Future<void> checkAuthentication() async {
    emit(const AuthLoading());

    final tokenResult = await _authRepository.getStoredToken();

    await tokenResult.fold(
      onSuccess: (token) async {
        // Token exists, try to get user
        final userResult = await _authRepository.getCurrentUser();

        await userResult.fold(
          onSuccess: (user) async {
            // Set token for API calls
            setAccessToken(token.accessToken);
            
            // Initialize database for this user
            await _initializeDatabase(user.id);
            
            // Sync system data in background (for offline mode)
            _syncSystemData();

            emit(Authenticated(user: user, token: token));
          },
          onError: (failure) async {
            emit(const Unauthenticated());
          },
        );
      },
      onError: (failure) async {
        emit(const Unauthenticated());
      },
    );
  }

  /// Logs in with username and password
  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _authRepository.login(
      username: username,
      password: password,
    );

    await result.fold(
      onSuccess: (token) async {
        // Set token for API calls
        setAccessToken(token.accessToken);

        // Get user details
        final userResult = await _authRepository.getCurrentUser();

        await userResult.fold(
          onSuccess: (user) async {
            // Initialize database for this user
            await _initializeDatabase(user.id);
            
            // Sync system data in background
            _syncSystemData();
            
            emit(Authenticated(user: user, token: token));
          },
          onError: (failure) async {
            emit(AuthError(failure));
          },
        );
      },
      onError: (failure) async {
        emit(AuthError(failure));
      },
    );
  }

  /// Logs in from webview with access token and user info
  Future<void> loginFromWebView({
    required String accessToken,
    required Map<String, dynamic> userInfo,
  }) async {
    emit(const AuthLoading());

    try {
      // Create token entity from access token
      final token = AuthTokenEntity(
        accessToken: accessToken,
        refreshToken: null,
        tokenType: 'Bearer',
        expiresAt: null,
      );

      // Save token
      final saveTokenResult = await _authRepository.saveToken(token);
      await saveTokenResult.fold(
        onSuccess: (_) {},
        onError: (failure) async {
          print('run failure ${failure.message}');
          emit(AuthError(failure));
          return;
        },
      );

      // Set token for API calls
      setAccessToken(accessToken);

      // Map user info from webview to UserModel
      // Webview sends all user fields including business_id, role_id, role_name, etc.
      final userModel = UserModel.fromJson(userInfo);

      // Cache user directly using local data source
      final authLocalDataSource = sl.get<AuthLocalDataSource>();
      await authLocalDataSource.cacheUser(userModel);

      // Initialize database for this user
      await _initializeDatabase(userModel.id);

      // Sync system data in background (like old code: SystemApi().store(), Variations().refresh())
      _syncSystemData();

      // Convert to entity using mapper
      final userMapper = const UserMapper();
      final userEntity = userMapper.toEntity(userModel);

      emit(Authenticated(user: userEntity, token: token));
    } catch (e) {
      emit(AuthError(UnknownFailure(message: e.toString())));
    }
  }

  /// Initialize database for user
  Future<void> _initializeDatabase(int userId) async {
    try {
      // Initialize both global and user databases
      await _databaseManager.initialize(userId);
      
      // Try to migrate from old database if it exists
      try {
        await MigrationHelper.migrateFromOldDatabase(userId: userId);
      } catch (e) {
        // Migration is optional, log but don't fail
        Logger.logI('Migration skipped or failed (this is OK for new users): $e');
      }
    } catch (e) {
      // Log error but don't fail login
      Logger.logE('Database initialization error', e);
    }
  }

  /// Sync system data in background (non-blocking)
  void _syncSystemData() async {
    // Run in background without blocking
    try{
      await _syncService.syncAll();
    }catch(e){
      Logger.logE('System sync error', e);
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    final currentUserId = currentUser?.id;
    
    emit(const AuthLoading());

    final result = await _authRepository.logout();

    await result.fold(
      onSuccess: (_) async {
        await _cleanupOnLogout(currentUserId);
        emit(const Unauthenticated());
      },
      onError: (failure) async {
        // Still logout locally even if API fails
        await _cleanupOnLogout(currentUserId);
        emit(const Unauthenticated());
      },
    );
  }

  /// Cleanup on logout - delete user database and clear cache
  Future<void> _cleanupOnLogout(int? userId) async {
    setAccessToken(null);
    
    try {
      // Delete user database (global database is kept)
      if (userId != null) {
        await _databaseManager.deleteUserDatabase(userId);
      }
      
      // Close database connections
      await _databaseManager.close();
      
      // Clear sync cache
      await _syncService.clearCache();
    } catch (e) {
      Logger.logE('Cleanup error', e);
    }
  }

  /// Force sync data
  Future<void> syncData() async {
    if (!isAuthenticated) return;
    
    try {
      await _syncService.syncAll();
    } catch (e) {
      Logger.logE('Sync error', e);
    }
  }

  /// Gets current user if authenticated
  UserEntity? get currentUser {
    final currentState = state;
    if (currentState is Authenticated) {
      return currentState.user;
    }
    return null;
  }

  /// Gets current token if authenticated
  AuthTokenEntity? get currentToken {
    final currentState = state;
    if (currentState is Authenticated) {
      return currentState.token;
    }
    return null;
  }

  /// Checks if user is authenticated
  bool get isAuthenticated => state is Authenticated;
}
