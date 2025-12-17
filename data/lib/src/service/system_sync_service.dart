import 'dart:convert';

import 'package:domain/domain.dart';

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
import '../utils/image_cache_helper.dart';

/// Service for syncing system data for offline mode
/// This mirrors the functionality of the original SystemApi class
class SystemSyncService {
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
  final String _baseUrl;

  const SystemSyncService({
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
    required String baseUrl,
  })  : _localDataSource = localDataSource,
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
        _contactLocalDataSource = contactLocalDataSource,
        _baseUrl = baseUrl;

  /// Sync all system data from remote to local storage
  /// This should be called after login to cache data for offline use
  Future<void> syncAll() async {
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
      
      Logger.logI('System sync completed successfully');
    } catch (e) {
      Logger.logE('System sync error', e);
      // Don't throw - allow app to continue with cached data
    }
  }

  /// Sync brands
  Future<void> _syncBrands() async {
    try {
      final brands = await _brandDataSource.getBrands();
      final brandsJson = brands.map((b) => b.toJson()).toList();
      await _localDataSource.insert('brand', jsonEncode(brandsJson));
      Logger.logI('Brands synced: ${brands.length}');
    } catch (e) {
      Logger.logE('Error syncing brands', e);
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
      Logger.logI('Categories synced: ${categories.length}, Sub-categories: $subCategoryCount');
    } catch (e) {
      Logger.logE('Error syncing categories: $e');
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
      Logger.logI('Locations synced: ${locations.length}, Payment methods: $paymentMethodCount');
    } catch (e) {
      Logger.logE('Error syncing locations: $e');
      // Silently fail
    }
  }

  /// Sync business details
  Future<void> _syncBusinessDetails() async {
    try {
      final business = await _businessDataSource.getBusinessDetails();
      await _localDataSource.insert('business', jsonEncode([business.toJson()]));
      Logger.logI('Business details synced');
    } catch (e) {
      Logger.logE('Error syncing business details: $e');
      // Silently fail
    }
  }

  /// Sync user permissions
  Future<void> _syncPermissions() async {
    try {
      final permissions = await _permissionDataSource.getUserPermissions();
      await _localDataSource.insert('user_permissions', jsonEncode(permissions));
      Logger.logI('Permissions synced: ${permissions.length}');
    } catch (e) {
      Logger.logE('Error syncing permissions: $e');
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
        Logger.logI('Active subscription synced');
      } else {
        await _localDataSource.insert('active-subscription', jsonEncode([]));
        Logger.logI('No active subscription');
      }
    } catch (e) {
      Logger.logE('Error syncing subscription: $e');
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
      Logger.logI('Payment methods synced: ${paymentMethods.length}');
    } catch (e) {
      Logger.logE('Error syncing payment methods: $e');
      // Silently fail
    }
  }

  /// Sync payment accounts
  Future<void> _syncPaymentAccounts() async {
    try {
      final paymentAccounts = await _paymentDataSource.getPaymentAccounts();

      // Process each account to download images
      final List<Map<String, dynamic>> processedAccounts = [];

      for (final account in paymentAccounts) {
        final Map<String, dynamic> processedAccount = Map.from(account);

        // Check if image_e_wallet exists and is not null
        final imageEWallet = account['image_e_wallet']?.toString();
        if (imageEWallet != null && imageEWallet.isNotEmpty) {
          try {
            // Construct full image URL
            // If image_e_wallet is already a full URL, use it; otherwise construct from baseUrl
            String imageUrl = imageEWallet;
            if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
              // Assume images are stored in /uploads/payment/ directory
              imageUrl = '$_baseUrl/uploads/payment/$imageEWallet';
            }

            // Download and cache the image
            final cachedPath = await ImageCacheHelper.downloadAndCacheImage(
              imageUrl: imageUrl,
              cacheSubdirectory: 'payment_accounts',
              fileName: '${account['id']}_$imageEWallet',
            );

            if (cachedPath != null) {
              processedAccount['cached_image_path'] = cachedPath;
            } else {
              // If download failed, clear cached_image_path
              processedAccount['cached_image_path'] = null;
            }
          } catch (e) {
            Logger.logE('Error downloading image for payment account ${account['id']}', e);
            processedAccount['cached_image_path'] = null;
          }
        } else {
          // No image, clear cached path
          processedAccount['cached_image_path'] = null;
        }

        processedAccounts.add(processedAccount);
      }

      // Save processed accounts to local storage
      await _localDataSource.insert(
        'payment_accounts',
        jsonEncode(processedAccounts),
      );
      Logger.logI('Payment accounts synced: ${processedAccounts.length}');
    } catch (e) {
      Logger.logE('Error syncing payment accounts: $e');
      // Silently fail
    }
  }

  /// Sync taxes
  Future<void> _syncTaxes() async {
    try {
      final taxes = await _taxDataSource.getTaxes();
      final taxesJson = taxes.map((t) => t.toJson()).toList();
      await _localDataSource.insert('tax', jsonEncode(taxesJson));
      Logger.logI('Taxes synced: ${taxes.length}');
    } catch (e) {
      Logger.logE('Error syncing taxes: $e');
      // Silently fail
    }
  }

  /// Sync contacts
  Future<void> _syncContacts() async {
    try {
      final contacts = await _contactDataSource.getContacts(perPage: -1, type: 'customer');
      // Save contacts to local database
      await _contactLocalDataSource.saveContacts(contacts);
      Logger.logI('Contacts synced: ${contacts.length}');
    } catch (e) {
      Logger.logE('Error syncing contacts: $e');
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
        Logger.logI('No locations found - skipping product sync');
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
              perPage: 1000,
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
            Logger.logI('Products synced for location ${location.id} (${location.name}): ${allProducts.length}');
          }
        } catch (e) {
          Logger.logE('Error syncing products for location ${location.id}: $e');
          // Continue with next location
        }
      }

      // Update last sync timestamp
      await _productLocalDataSource.updateLastSync();
      Logger.logI('Total products synced: $totalProducts');
    } catch (e) {
      Logger.logE('Error syncing products: $e');
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
      Logger.logE('Error getting last sync time', e);
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
      await ImageCacheHelper.clearCache(cacheSubdirectory: 'payment_accounts');
      Logger.logI('System cache cleared');
    } catch (e) {
      Logger.logE('Error clearing cache', e);
    }
  }
}
