import 'package:data/data.dart';
import 'package:domain/domain.dart';

import 'app_config.dart';
import 'env_config.dart';

/// Service Locator for dependency injection
/// This is a simple implementation. For production, consider using get_it package.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  /// Register a service
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Register a lazy singleton
  void registerLazy<T>(T Function() factory) {
    _services[T] = _LazyService(factory);
  }

  /// Get a registered service
  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service $T not registered');
    }
    if (service is _LazyService<T>) {
      return service.get();
    }
    return service as T;
  }

  /// Check if a service is registered
  bool isRegistered<T>() => _services.containsKey(T);

  /// Clear all services
  void clear() => _services.clear();
}

class _LazyService<T> {
  final T Function() _factory;
  T? _instance;

  _LazyService(this._factory);

  T get() {
    _instance ??= _factory();
    return _instance!;
  }
}

/// Global service locator instance
final sl = ServiceLocator();

/// Initialize all dependencies
Future<void> initDependencies({Environment env = Environment.development}) async {
  // Load config from environment
  final config = await EnvConfig.load(env);

  // Core
  sl.register<AppConfig>(config);
  sl.register<NetworkInfo>(NetworkInfoImpl());

  // Database
  sl.register<DatabaseHelper>(DatabaseHelper.instance);

  // API Client
  sl.registerLazy<ApiClient>(() => ApiClient(baseUrl: config.baseUrl));

  // Data Sources - Remote
  sl.registerLazy<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        clientId: config.clientId,
        clientSecret: config.clientSecret,
        loginUrl: config.loginUrl,
        userUrl: config.userEndpoint,
      ));

  sl.registerLazy<BrandRemoteDataSource>(() => BrandRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/brand',
      ));

  sl.registerLazy<ContactRemoteDataSource>(() => ContactRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/contactapi',
      ));

  // Data Sources - Local
  sl.registerLazy<AuthLocalDataSource>(() => AuthLocalDataSourceImpl());
  sl.registerLazy<ProductLocalDataSource>(() => ProductLocalDataSourceImpl());

  // Repositories
  sl.registerLazy<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl.get<AuthRemoteDataSource>(),
        localDataSource: sl.get<AuthLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<BrandRepository>(() => BrandRepositoryImpl(
        remoteDataSource: sl.get<BrandRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  // Use Cases - Auth
  sl.registerLazy<LoginUseCase>(
    () => LoginUseCase(sl.get<AuthRepository>()),
  );

  sl.registerLazy<LogoutUseCase>(
    () => LogoutUseCase(sl.get<AuthRepository>()),
  );

  sl.registerLazy<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(sl.get<AuthRepository>()),
  );

  // Use Cases - Brand
  sl.registerLazy<GetBrandsUseCase>(
    () => GetBrandsUseCase(sl.get<BrandRepository>()),
  );

  sl.registerLazy<CreateBrandUseCase>(
    () => CreateBrandUseCase(sl.get<BrandRepository>()),
  );

  sl.registerLazy<DeleteBrandUseCase>(
    () => DeleteBrandUseCase(sl.get<BrandRepository>()),
  );
}

/// Set the access token for authenticated requests
void setAccessToken(String? token) {
  if (sl.isRegistered<ApiClient>()) {
    sl.get<ApiClient>().setAccessToken(token);
  }
}

/// Initialize database for a user
Future<void> initDatabase(int userId) async {
  await sl.get<DatabaseHelper>().initDatabase(userId);
}
