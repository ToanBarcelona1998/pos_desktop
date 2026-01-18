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
import '../data_source/remote/layout_bill_remote_data_source.dart';
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
  final LayoutBillRemoteDataSource _layoutBillDataSource;
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
    required LayoutBillRemoteDataSource layoutBillDataSource,
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
        _layoutBillDataSource = layoutBillDataSource,
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

      // Sync layout bill after locations are synced (requires location_id)
      await _syncLayoutBill();

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

  /// Sync layout bill for each location
  Future<void> _syncLayoutBill() async {
    try {
      // Get all locations first
      final locationsData = await _localDataSource.get('location');
      if (locationsData == null) {
        Logger.logI('No locations found - skipping layout bill sync');
        return;
      }

      final List<dynamic> locationsList = locationsData is String 
          ? jsonDecode(locationsData) 
          : locationsData;

      if (locationsList.isEmpty) {
        Logger.logI('No locations found - skipping layout bill sync');
        return;
      }

      int syncedCount = 0;

      // Sync layout bill for each location
      for (final locationJson in locationsList) {
        try {
          final locationId = locationJson['id'] as int;
          final layoutBillData = await _layoutBillDataSource.getLayoutBill(locationId);

          // Download and cache business logo if exists
          final businessData = layoutBillData['business'] as Map<String, dynamic>?;
          if (businessData != null) {
            final invoiceLayout = layoutBillData['invoice_layout'];
            final logo = invoiceLayout['logo']?.toString();
            if (logo != null && logo.isNotEmpty) {
              try {
                String imageUrl = logo;
                // If logo is not a full URL, it's already a full URL from the API
                // but we check just in case
                if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
                  imageUrl = '$_baseUrl$logo';
                }

                final cachedPath = await ImageCacheHelper.downloadAndCacheImage(
                  imageUrl: imageUrl,
                  cacheSubdirectory: 'layout_bill',
                  fileName: '${locationId}_business_logo.png',
                );

                if (cachedPath != null) {
                  businessData['cached_logo_path'] = cachedPath;
                } else {
                  businessData['cached_logo_path'] = null;
                }
              } catch (e) {
                Logger.logE('Error downloading business logo for location $locationId', e);
                businessData['cached_logo_path'] = null;
              }
            } else {
              businessData['cached_logo_path'] = null;
            }
          }

          // Save layout bill data to local storage with locationId as keyId
          await _localDataSource.insert(
            'layout_bill',
            jsonEncode(layoutBillData),
            locationId,
          );

          syncedCount++;
        } catch (e) {
          Logger.logE('Error syncing layout bill for location', e);
          // Continue with next location
        }
      }

      Logger.logI('Layout bills synced: $syncedCount');
    } catch (e) {
      Logger.logE('Error syncing layout bills: $e');
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
    final Map<int, List<ProductModel>> allProducts = {};
    int totalProducts = 0;
    
    try {
      // Get all locations first
      final locations = await _locationDataSource.getLocations();
      if (locations.isEmpty) {
        Logger.logI('No locations found - skipping product sync');
        return;
      }
      
      // Sync products for each location
      for (final location in locations) {
        try {
          int page = 1;
          bool hasMore = true;
          List<ProductModel> locationProducts = [];

          // Sync all pages for this location
          while (hasMore) {
            final response = await _productDataSource.getProducts(
              locationId: location.id,
              page: page,
              perPage: 1000,
            );

            // Append products from this page (don't overwrite)
            locationProducts.addAll(response.products);
            hasMore = response.hasMore;
            page++;
          }

          // Save all products for this location
          if (locationProducts.isNotEmpty) {
            allProducts[location.id] = locationProducts;
          }
        } catch (e) {
          Logger.logE('Error syncing products for location ${location.id}: $e');
          // Continue with next location
        }
      }

      // Save products to local database and calculate total
      if (allProducts.isNotEmpty) {
        for (final locationId in allProducts.keys.toList()) {
          final products = allProducts[locationId]!;

          await _productLocalDataSource.saveProducts(
            products,
            locationId,
          );

          totalProducts += products.length;
          Logger.logI('Products synced for location $locationId: ${products.length}');
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
      await ImageCacheHelper.clearCache(cacheSubdirectory: 'layout_bill');
      Logger.logI('System cache cleared');
    } catch (e) {
      Logger.logE('Error clearing cache', e);
    }
  }
}
