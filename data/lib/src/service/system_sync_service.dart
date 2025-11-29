import 'dart:convert';

import '../core/network_info.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/brand_remote_data_source.dart';
import '../data_source/remote/business_remote_data_source.dart';
import '../data_source/remote/category_remote_data_source.dart';
import '../data_source/remote/contact_remote_data_source.dart';
import '../data_source/remote/location_remote_data_source.dart';
import '../data_source/remote/payment_remote_data_source.dart';
import '../data_source/remote/permission_remote_data_source.dart';
import '../data_source/remote/subscription_remote_data_source.dart';
import '../data_source/remote/tax_remote_data_source.dart';

/// Service for syncing system data for offline mode
/// This mirrors the functionality of the original SystemApi class
class SystemSyncService {
  final NetworkInfo _networkInfo;
  final SystemLocalDataSource _localDataSource;
  final BrandRemoteDataSource _brandDataSource;
  final CategoryRemoteDataSource _categoryDataSource;
  final LocationRemoteDataSource _locationDataSource;
  final BusinessRemoteDataSource _businessDataSource;
  final PermissionRemoteDataSource _permissionDataSource;
  final SubscriptionRemoteDataSource _subscriptionDataSource;
  final PaymentRemoteDataSource _paymentDataSource;
  final TaxRemoteDataSource _taxDataSource;
  final ContactRemoteDataSource _contactDataSource;

  const SystemSyncService({
    required NetworkInfo networkInfo,
    required SystemLocalDataSource localDataSource,
    required BrandRemoteDataSource brandDataSource,
    required CategoryRemoteDataSource categoryDataSource,
    required LocationRemoteDataSource locationDataSource,
    required BusinessRemoteDataSource businessDataSource,
    required PermissionRemoteDataSource permissionDataSource,
    required SubscriptionRemoteDataSource subscriptionDataSource,
    required PaymentRemoteDataSource paymentDataSource,
    required TaxRemoteDataSource taxDataSource,
    required ContactRemoteDataSource contactDataSource,
  })  : _networkInfo = networkInfo,
        _localDataSource = localDataSource,
        _brandDataSource = brandDataSource,
        _categoryDataSource = categoryDataSource,
        _locationDataSource = locationDataSource,
        _businessDataSource = businessDataSource,
        _permissionDataSource = permissionDataSource,
        _subscriptionDataSource = subscriptionDataSource,
        _paymentDataSource = paymentDataSource,
        _taxDataSource = taxDataSource,
        _contactDataSource = contactDataSource;

  /// Sync all system data from remote to local storage
  /// This should be called after login to cache data for offline use
  Future<void> syncAll() async {
    if (!await _networkInfo.isConnected) {
      throw Exception('No internet connection');
    }

    // Sync all data in parallel
    await Future.wait([
      _syncBrands(),
      _syncCategories(),
      _syncLocations(),
      _syncBusinessDetails(),
      _syncPermissions(),
      _syncActiveSubscription(),
      _syncPaymentMethods(),
      _syncPaymentAccounts(),
      _syncTaxes(),
    ]);

    // Sync contacts after system data
    await _syncContacts();

    // Update last sync timestamp
    await _localDataSource.insert(
      'last_sync',
      DateTime.now().toIso8601String(),
    );
  }

  /// Sync brands
  Future<void> _syncBrands() async {
    try {
      final brands = await _brandDataSource.getBrands();
      final brandsJson = brands.map((b) => b.toJson()).toList();
      await _localDataSource.insert('brand', jsonEncode(brandsJson));
    } catch (_) {
      // Silently fail - data might not be available
    }
  }

  /// Sync categories
  Future<void> _syncCategories() async {
    try {
      final categories = await _categoryDataSource.getCategories();
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await _localDataSource.insert('taxonomy', jsonEncode(categoriesJson));

      // Store sub-categories separately
      for (final category in categories) {
        if (category.subCategories.isNotEmpty) {
          for (final subCategory in category.subCategories) {
            await _localDataSource.insert(
              'sub_categories',
              jsonEncode({'id': subCategory.id, 'name': subCategory.name}),
              category.id,
            );
          }
        }
      }
    } catch (_) {
      // Silently fail
    }
  }

  /// Sync locations
  Future<void> _syncLocations() async {
    try {
      final locations = await _locationDataSource.getLocations();
      final locationsJson = locations.map((l) => l.toJson()).toList();
      await _localDataSource.insert('location', jsonEncode(locationsJson));

      // Store payment methods per location
      for (final location in locations) {
        if (location.paymentMethods != null) {
          await _localDataSource.insert(
            'payment_method',
            jsonEncode(location.paymentMethods),
            location.id,
          );
        }
      }
    } catch (_) {
      // Silently fail
    }
  }

  /// Sync business details
  Future<void> _syncBusinessDetails() async {
    try {
      final business = await _businessDataSource.getBusinessDetails();
      await _localDataSource.insert('business', jsonEncode([business.toJson()]));
    } catch (_) {
      // Silently fail
    }
  }

  /// Sync user permissions
  Future<void> _syncPermissions() async {
    try {
      final permissions = await _permissionDataSource.getUserPermissions();
      await _localDataSource.insert('user_permissions', jsonEncode(permissions));
    } catch (_) {
      // Silently fail
    }
  }

  /// Sync active subscription
  Future<void> _syncActiveSubscription() async {
    try {
      final subscription = await _subscriptionDataSource.getActiveSubscription();
      if (subscription != null) {
        await _localDataSource.insert(
          'active-subscription',
          jsonEncode([subscription.toJson()]),
        );
      } else {
        await _localDataSource.insert('active-subscription', jsonEncode([]));
      }
    } catch (_) {
      // Silently fail
    }
  }

  /// Sync payment methods
  Future<void> _syncPaymentMethods() async {
    try {
      final paymentMethods = await _paymentDataSource.getPaymentMethods();
      await _localDataSource.insert(
        'payment_methods',
        jsonEncode(paymentMethods),
      );
    } catch (_) {
      // Silently fail
    }
  }

  /// Sync payment accounts
  Future<void> _syncPaymentAccounts() async {
    try {
      final paymentAccounts = await _paymentDataSource.getPaymentAccounts();
      await _localDataSource.insert(
        'payment_accounts',
        jsonEncode(paymentAccounts),
      );
    } catch (_) {
      // Silently fail
    }
  }

  /// Sync taxes
  Future<void> _syncTaxes() async {
    try {
      final taxes = await _taxDataSource.getTaxes();
      final taxesJson = taxes.map((t) => t.toJson()).toList();
      await _localDataSource.insert('tax', jsonEncode(taxesJson));
    } catch (_) {
      // Silently fail
    }
  }

  /// Sync contacts
  Future<void> _syncContacts() async {
    try {
      final contacts = await _contactDataSource.getContacts();
      // Contacts are stored directly in the database by the data source
      // This is just to trigger the sync
      final _ = contacts;
    } catch (_) {
      // Silently fail
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    final value = await _localDataSource.get('last_sync');
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Check if data needs to be synced (older than specified duration)
  Future<bool> needsSync({Duration maxAge = const Duration(hours: 1)}) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }

  /// Clear all cached system data
  Future<void> clearCache() async {
    await _localDataSource.clearAll();
  }
}

