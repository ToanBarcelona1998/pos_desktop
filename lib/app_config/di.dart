import 'package:data/data.dart';
import 'package:domain/domain.dart';

import 'app_config.dart';
import 'env_config.dart';

/// Service Locator for dependency injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};

  void register<T>(T service) {
    _services[T] = service;
  }

  void registerLazy<T>(T Function() factory) {
    _services[T] = _LazyService(factory);
  }

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

  bool isRegistered<T>() => _services.containsKey(T);

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

final sl = ServiceLocator();

/// Initialize all dependencies
Future<void> initDependencies({Environment env = Environment.development}) async {
  final config = await EnvConfig.load(env);

  // ============== Core ==============
  sl.register<AppConfig>(config);
  sl.register<NetworkInfo>(NetworkInfoImpl());
  sl.register<DatabaseHelper>(DatabaseHelper.instance);
  sl.registerLazy<ApiClient>(() => ApiClient(baseUrl: config.baseUrl));

  // ============== Local Data Sources ==============
  sl.registerLazy<AuthLocalDataSource>(() => AuthLocalDataSourceImpl());
  sl.registerLazy<ProductLocalDataSource>(() => ProductLocalDataSourceImpl());
  sl.registerLazy<ContactLocalDataSource>(() => ContactLocalDataSourceImpl());
  sl.registerLazy<SystemLocalDataSource>(() => SystemLocalDataSourceImpl(
        databaseHelper: sl.get<DatabaseHelper>(),
      ));

  // ============== Remote Data Sources ==============
  _registerRemoteDataSources(config);

  // ============== Repositories ==============
  _registerRepositories();

  // ============== Services ==============
  _registerServices();

  // ============== Use Cases ==============
  _registerUseCases();
}

void _registerRemoteDataSources(AppConfig config) {
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

  sl.registerLazy<AttendanceRemoteDataSource>(() => AttendanceRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        checkInEndpoint: '${config.apiUrl}/clock-in',
        checkOutEndpoint: '${config.apiUrl}/clock-out',
        getAttendanceEndpoint: '${config.apiUrl}/get-attendance/',
      ));

  sl.registerLazy<TaxRemoteDataSource>(() => TaxRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/tax',
      ));

  sl.registerLazy<UnitRemoteDataSource>(() => UnitRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/unit',
      ));

  sl.registerLazy<ExpenseRemoteDataSource>(() => ExpenseRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        expenseEndpoint: '${config.apiUrl}/expense',
        categoriesEndpoint: '${config.apiUrl}/expense-categories',
      ));

  sl.registerLazy<FieldForceRemoteDataSource>(() => FieldForceRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        createEndpoint: '${config.apiUrl}/field-force/create',
        updateEndpoint: '${config.apiUrl}/field-force/update-visit-status',
      ));

  sl.registerLazy<FollowUpRemoteDataSource>(() => FollowUpRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        followUpEndpoint: '${config.apiUrl}/crm/follow-ups',
        callLogEndpoint: '${config.apiUrl}/crm/call-logs',
        categoriesEndpoint: '${config.apiUrl}/taxonomy?type=followup_category',
      ));

  sl.registerLazy<ShipmentRemoteDataSource>(() => ShipmentRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        sellEndpoint: '${config.apiUrl}/sell',
        updateStatusEndpoint: '${config.apiUrl}/update-shipping-status',
      ));

  sl.registerLazy<CategoryRemoteDataSource>(() => CategoryRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/taxonomy',
      ));

  sl.registerLazy<LocationRemoteDataSource>(() => LocationRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/business-location',
      ));

  sl.registerLazy<BusinessRemoteDataSource>(() => BusinessRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/business-details',
      ));

  sl.registerLazy<PaymentRemoteDataSource>(() => PaymentRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        paymentMethodsEndpoint: '${config.apiUrl}/payment-methods',
        paymentAccountsEndpoint: '${config.apiUrl}/payment-accounts',
        contactEndpoint: '${config.apiUrl}/contactapi',
        contactPaymentEndpoint: '${config.apiUrl}/contact-payment',
      ));

  sl.registerLazy<VariationRemoteDataSource>(() => VariationRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
      ));

  sl.registerLazy<ReportRemoteDataSource>(() => ReportRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        profitLossEndpoint: '${config.apiUrl}/profit-loss-report',
        productStockEndpoint: '${config.apiUrl}/product-stock-report',
      ));

  sl.registerLazy<SubscriptionRemoteDataSource>(() => SubscriptionRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/active-subscription',
      ));

  sl.registerLazy<PermissionRemoteDataSource>(() => PermissionRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/user/loggedin',
      ));

  sl.registerLazy<ProductRemoteDataSource>(() => ProductRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/variation', // Use variation endpoint like old code
      ));

  sl.registerLazy<PurchaseRemoteDataSource>(() => PurchaseRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/purchases',
      ));

  sl.registerLazy<SellRemoteDataSource>(() => SellRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/sell',
      ));

  sl.registerLazy<NotificationRemoteDataSource>(() => NotificationRemoteDataSourceImpl(
        apiClient: sl.get<ApiClient>(),
        endpoint: '${config.apiUrl}/notifications',
      ));
}

void _registerRepositories() {
  sl.registerLazy<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl.get<AuthRemoteDataSource>(),
        localDataSource: sl.get<AuthLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<BrandRepository>(() => BrandRepositoryImpl(
        remoteDataSource: sl.get<BrandRemoteDataSource>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<ContactRepository>(() => ContactRepositoryImpl(
        remoteDataSource: sl.get<ContactRemoteDataSource>(),
        localDataSource: sl.get<ContactLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<AttendanceRepository>(() => AttendanceRepositoryImpl(
        remoteDataSource: sl.get<AttendanceRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<TaxRepository>(() => TaxRepositoryImpl(
        remoteDataSource: sl.get<TaxRemoteDataSource>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<UnitRepository>(() => UnitRepositoryImpl(
        remoteDataSource: sl.get<UnitRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<ExpenseRepository>(() => ExpenseRepositoryImpl(
        remoteDataSource: sl.get<ExpenseRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<FieldForceRepository>(() => FieldForceRepositoryImpl(
        remoteDataSource: sl.get<FieldForceRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<FollowUpRepository>(() => FollowUpRepositoryImpl(
        remoteDataSource: sl.get<FollowUpRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<ShipmentRepository>(() => ShipmentRepositoryImpl(
        remoteDataSource: sl.get<ShipmentRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<CategoryRepository>(() => CategoryRepositoryImpl(
        remoteDataSource: sl.get<CategoryRemoteDataSource>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<LocationRepository>(() => LocationRepositoryImpl(
        remoteDataSource: sl.get<LocationRemoteDataSource>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<BusinessRepository>(() => BusinessRepositoryImpl(
        remoteDataSource: sl.get<BusinessRemoteDataSource>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<PaymentRepository>(() => PaymentRepositoryImpl(
        remoteDataSource: sl.get<PaymentRemoteDataSource>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<VariationRepository>(() => VariationRepositoryImpl(
        remoteDataSource: sl.get<VariationRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<ReportRepository>(() => ReportRepositoryImpl(
        remoteDataSource: sl.get<ReportRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<SubscriptionRepository>(() => SubscriptionRepositoryImpl(
        remoteDataSource: sl.get<SubscriptionRemoteDataSource>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<PermissionRepository>(() => PermissionRepositoryImpl(
        remoteDataSource: sl.get<PermissionRemoteDataSource>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<ProductRepository>(() => ProductRepositoryImpl(
        remoteDataSource: sl.get<ProductRemoteDataSource>(),
        localDataSource: sl.get<ProductLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<PurchaseRepository>(() => PurchaseRepositoryImpl(
        remoteDataSource: sl.get<PurchaseRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<SellLocalDataSource>(() => SellLocalDataSourceImpl(
        dbHelper: sl.get<DatabaseHelper>(),
      ));

  sl.registerLazy<SellRepository>(() => SellRepositoryImpl(
        remoteDataSource: sl.get<SellRemoteDataSource>(),
        localDataSource: sl.get<SellLocalDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));

  sl.registerLazy<NotificationRepository>(() => NotificationRepositoryImpl(
        remoteDataSource: sl.get<NotificationRemoteDataSource>(),
        networkInfo: sl.get<NetworkInfo>(),
      ));
}

void _registerServices() {
  sl.registerLazy<SystemSyncService>(() => SystemSyncService(
        networkInfo: sl.get<NetworkInfo>(),
        localDataSource: sl.get<SystemLocalDataSource>(),
        brandDataSource: sl.get<BrandRemoteDataSource>(),
        categoryDataSource: sl.get<CategoryRemoteDataSource>(),
        locationDataSource: sl.get<LocationRemoteDataSource>(),
        businessDataSource: sl.get<BusinessRemoteDataSource>(),
        permissionDataSource: sl.get<PermissionRemoteDataSource>(),
        subscriptionDataSource: sl.get<SubscriptionRemoteDataSource>(),
        paymentDataSource: sl.get<PaymentRemoteDataSource>(),
        taxDataSource: sl.get<TaxRemoteDataSource>(),
        contactDataSource: sl.get<ContactRemoteDataSource>(),
        productDataSource: sl.get<ProductRemoteDataSource>(),
        productLocalDataSource: sl.get<ProductLocalDataSource>(),
        contactLocalDataSource: sl.get<ContactLocalDataSource>(),
      ));
}

void _registerUseCases() {
  // Auth
  sl.registerLazy<LoginUseCase>(() => LoginUseCase(sl.get<AuthRepository>()));
  sl.registerLazy<LogoutUseCase>(() => LogoutUseCase(sl.get<AuthRepository>()));
  sl.registerLazy<GetCurrentUserUseCase>(() => GetCurrentUserUseCase(sl.get<AuthRepository>()));

  // Attendance
  sl.registerLazy<ClockInUseCase>(() => ClockInUseCase(sl.get<AttendanceRepository>()));
  sl.registerLazy<ClockOutUseCase>(() => ClockOutUseCase(sl.get<AttendanceRepository>()));
  sl.registerLazy<GetAttendanceUseCase>(() => GetAttendanceUseCase(sl.get<AttendanceRepository>()));

  // Brand
  sl.registerLazy<GetBrandsUseCase>(() => GetBrandsUseCase(sl.get<BrandRepository>()));
  sl.registerLazy<CreateBrandUseCase>(() => CreateBrandUseCase(sl.get<BrandRepository>()));
  sl.registerLazy<DeleteBrandUseCase>(() => DeleteBrandUseCase(sl.get<BrandRepository>()));

  // Category
  sl.registerLazy<GetCategoriesUseCase>(() => GetCategoriesUseCase(sl.get<CategoryRepository>()));
  sl.registerLazy<SyncCategoriesUseCase>(() => SyncCategoriesUseCase(sl.get<CategoryRepository>()));

  // Contact
  sl.registerLazy<GetContactsUseCase>(() => GetContactsUseCase(sl.get<ContactRepository>()));
  sl.registerLazy<SearchContactsUseCase>(() => SearchContactsUseCase(sl.get<ContactRepository>()));

  // Expense
  sl.registerLazy<GetExpenseCategoriesUseCase>(() => GetExpenseCategoriesUseCase(sl.get<ExpenseRepository>()));
  sl.registerLazy<CreateExpenseUseCase>(() => CreateExpenseUseCase(sl.get<ExpenseRepository>()));

  // Location
  sl.registerLazy<GetLocationsUseCase>(() => GetLocationsUseCase(sl.get<LocationRepository>()));

  // Notification
  sl.registerLazy<GetNotificationsUseCase>(() => GetNotificationsUseCase(sl.get<NotificationRepository>()));
  sl.registerLazy<GetUnreadCountUseCase>(() => GetUnreadCountUseCase(sl.get<NotificationRepository>()));
  sl.registerLazy<MarkNotificationAsReadUseCase>(() => MarkNotificationAsReadUseCase(sl.get<NotificationRepository>()));

  // Product
  sl.registerLazy<GetProductsUseCase>(() => GetProductsUseCase(sl.get<ProductRepository>()));
  sl.registerLazy<SearchProductsUseCase>(() => SearchProductsUseCase(sl.get<ProductRepository>()));

  // Purchase
  sl.registerLazy<GetPurchasesUseCase>(() => GetPurchasesUseCase(sl.get<PurchaseRepository>()));

  // Report
  sl.registerLazy<GetProfitLossReportUseCase>(() => GetProfitLossReportUseCase(sl.get<ReportRepository>()));
  sl.registerLazy<GetProductStockReportUseCase>(() => GetProductStockReportUseCase(sl.get<ReportRepository>()));

  // Sell
  sl.registerLazy<GetLocalSellsUseCase>(() => GetLocalSellsUseCase(sl.get<SellRepository>()));
  sl.registerLazy<GetSellsByIdsUseCase>(() => GetSellsByIdsUseCase(sl.get<SellRepository>()));
  sl.registerLazy<CreateSellUseCase>(() => CreateSellUseCase(
    sl.get<SellRepository>(),
  ));

  // Tax
  sl.registerLazy<GetTaxesUseCase>(() => GetTaxesUseCase(sl.get<TaxRepository>()));
  sl.registerLazy<SyncTaxesUseCase>(() => SyncTaxesUseCase(sl.get<TaxRepository>()));

  // Unit
  sl.registerLazy<GetUnitsUseCase>(() => GetUnitsUseCase(sl.get<UnitRepository>()));
  sl.registerLazy<CreateUnitUseCase>(() => CreateUnitUseCase(sl.get<UnitRepository>()));
}

void setAccessToken(String? token) {
  if (sl.isRegistered<ApiClient>()) {
    sl.get<ApiClient>().setAccessToken(token);
  }
}
