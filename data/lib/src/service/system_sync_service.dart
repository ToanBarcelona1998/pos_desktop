import 'dart:convert';

import '../core/network_info.dart';
import '../data_source/local/contact_local_data_source.dart';
import '../data_source/local/product_local_data_source.dart';
import '../data_source/local/system_local_data_source.dart';
import '../model/product_model.dart';
import '../data_source/remote/brand_remote_data_source.dart';
import '../data_source/remote/business_remote_data_source.dart';
import '../data_source/remote/category_remote_data_source.dart';
import '../data_source/remote/contact_remote_data_source.dart';
import '../data_source/remote/location_remote_data_source.dart';
import '../data_source/remote/payment_remote_data_source.dart';
import '../data_source/remote/permission_remote_data_source.dart';
import '../data_source/remote/product_remote_data_source.dart';
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
  final ProductRemoteDataSource _productDataSource;
  final ProductLocalDataSource _productLocalDataSource;
  final ContactLocalDataSource _contactLocalDataSource;

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
    required ProductRemoteDataSource productDataSource,
    required ProductLocalDataSource productLocalDataSource,
    required ContactLocalDataSource contactLocalDataSource,
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
        _contactDataSource = contactDataSource,
        _productDataSource = productDataSource,
        _productLocalDataSource = productLocalDataSource,
        _contactLocalDataSource = contactLocalDataSource;

  /// Sync all system data from remote to local storage
  /// This should be called after login to cache data for offline use
  Future<void> syncAll() async {
    // Check network but don't throw - allow partial sync if some data exists
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      print('No internet connection - skipping sync');
      return;
    }

    try {
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
      ], eagerError: false);

      // Sync contacts after system data
      await _syncContacts();

      // Sync products for all locations (after locations are synced)
      await _syncProducts();

      // Update last sync timestamp
      await _localDataSource.insert(
        'last_sync',
        DateTime.now().toIso8601String(),
      );
      
      print('System sync completed successfully');
    } catch (e) {
      print('System sync error: $e');
      // Don't throw - allow app to continue with cached data
    }
  }

  /// Sync brands
  Future<void> _syncBrands() async {
    try {
      final brands = await _brandDataSource.getBrands();
      final brandsJson = brands.map((b) => b.toJson()).toList();
      await _localDataSource.insert('brand', jsonEncode(brandsJson));
      print('Brands synced: ${brands.length}');
    } catch (e) {
      print('Error syncing brands: $e');
      // Silently fail - data might not be available
    }
  }

  /// Sync categories
  Future<void> _syncCategories() async {
    try {
      final categories = await _categoryDataSource.getCategories();
      final categoriesJson = categories.map((c) => c.toJson()).toList();
      await _localDataSource.insert('taxonomy', jsonEncode(categoriesJson));

      // Store sub-categories separately with keyId (parent_id)
      int subCategoryCount = 0;
      for (final category in categories) {
        if (category.subCategories.isNotEmpty) {
          for (final subCategory in category.subCategories) {
            await _localDataSource.insert(
              'sub_categories',
              jsonEncode({'id': subCategory.id, 'name': subCategory.name}),
              category.id, // keyId is the parent_id
            );
            subCategoryCount++;
          }
        }
      }
      print('Categories synced: ${categories.length}, Sub-categories: $subCategoryCount');
    } catch (e) {
      print('Error syncing categories: $e');
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
      int paymentMethodCount = 0;
      for (final location in locations) {
        if (location.paymentMethods != null && location.paymentMethods!.isNotEmpty) {
          await _localDataSource.insert(
            'payment_method',
            jsonEncode(location.paymentMethods),
            location.id,
          );
          paymentMethodCount++;
        }
      }
      print('Locations synced: ${locations.length}, Payment methods: $paymentMethodCount');
    } catch (e) {
      print('Error syncing locations: $e');
      // Silently fail
    }
  }

  /// Sync business details
  Future<void> _syncBusinessDetails() async {
    try {
      final business = await _businessDataSource.getBusinessDetails();
      await _localDataSource.insert('business', jsonEncode([business.toJson()]));
      print('Business details synced');
    } catch (e) {
      print('Error syncing business details: $e');
      // Silently fail
    }
  }

  /// Sync user permissions
  Future<void> _syncPermissions() async {
    try {
      final permissions = await _permissionDataSource.getUserPermissions();
      await _localDataSource.insert('user_permissions', jsonEncode(permissions));
      print('Permissions synced: ${permissions.length}');
    } catch (e) {
      print('Error syncing permissions: $e');
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
        print('Active subscription synced');
      } else {
        await _localDataSource.insert('active-subscription', jsonEncode([]));
        print('No active subscription');
      }
    } catch (e) {
      print('Error syncing subscription: $e');
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
      print('Payment methods synced: ${paymentMethods.length}');
    } catch (e) {
      print('Error syncing payment methods: $e');
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
      print('Payment accounts synced: ${paymentAccounts.length}');
    } catch (e) {
      print('Error syncing payment accounts: $e');
      // Silently fail
    }
  }

  /// Sync taxes
  Future<void> _syncTaxes() async {
    try {
      final taxes = await _taxDataSource.getTaxes();
      final taxesJson = taxes.map((t) => t.toJson()).toList();
      await _localDataSource.insert('tax', jsonEncode(taxesJson));
      print('Taxes synced: ${taxes.length}');
    } catch (e) {
      print('Error syncing taxes: $e');
      // Silently fail
    }
  }

  /// Sync contacts
  Future<void> _syncContacts() async {
    try {
      final contacts = await _contactDataSource.getContacts(perPage: 750);
      // Save contacts to local database
      await _contactLocalDataSource.saveContacts(contacts);
      print('Contacts synced: ${contacts.length}');
    } catch (e) {
      print('Error syncing contacts: $e');
      // Silently fail
    }
  }

  /// Sync products for all locations
  /// Similar to old Variations.store() - syncs all products for each location
  Future<void> _syncProducts() async {
    try {
      // Get all locations first
      final locations = await _locationDataSource.getLocations();
      if (locations.isEmpty) {
        print('No locations found - skipping product sync');
        return;
      }

      int totalProducts = 0;
      
      // Sync products for each location
      for (final location in locations) {
        try {
          int page = 1;
          bool hasMore = true;
          final List<dynamic> allProducts = [];

          // Sync all pages for this location
          while (hasMore) {
            final response = await _productDataSource.getProducts(
              locationId: location.id,
              page: page,
              perPage: 100,
            );

            // response.products is already List<ProductModel>
            allProducts.addAll(response.products);
            hasMore = response.hasMore;
            page++;
          }

          // Save products to local database
          if (allProducts.isNotEmpty) {
            // allProducts contains ProductModel instances from ProductListResponse
            final productModels = allProducts
                .map((p) => p as ProductModel)
                .toList();
            
            await _productLocalDataSource.saveProducts(
              productModels,
              location.id,
            );
            
            totalProducts += allProducts.length;
            print('Products synced for location ${location.id} (${location.name}): ${allProducts.length}');
          }
        } catch (e) {
          print('Error syncing products for location ${location.id}: $e');
          // Continue with next location
        }
      }

      // Update last sync timestamp
      await _productLocalDataSource.updateLastSync();
      print('Total products synced: $totalProducts');
    } catch (e) {
      print('Error syncing products: $e');
      // Silently fail
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final value = await _localDataSource.get('last_sync');
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  /// Check if data needs to be synced (older than specified duration)
  Future<bool> needsSync({Duration maxAge = const Duration(hours: 1)}) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > maxAge;
  }

  /// Clear all cached system data
  Future<void> clearCache() async {
    try {
      await _localDataSource.clearAll();
      await _productLocalDataSource.clearCache();
      await _contactLocalDataSource.clearCache();
      print('System cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }
}
