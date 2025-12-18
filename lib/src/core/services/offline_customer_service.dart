import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:domain/domain.dart';

import '../../presentation/pages/pos/pos.dart';

/// Simplified cart item for transmission between windows
class CartSyncItem {
  final int productId;
  final int variationId;
  final String productName;
  final String? displayName;
  final int quantity;
  final double unitPrice;
  final double discountAmount;
  final String discountType; // 'fixed' or 'percentage'
  final double lineTotal;
  final String? productImageUrl;

  CartSyncItem({
    required this.productId,
    required this.variationId,
    required this.productName,
    this.displayName,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.discountType,
    required this.lineTotal,
    this.productImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'variationId': variationId,
      'productName': productName,
      'displayName': displayName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountAmount': discountAmount,
      'discountType': discountType,
      'lineTotal': lineTotal,
      'productImageUrl': productImageUrl,
    };
  }

  factory CartSyncItem.fromJson(Map<String, dynamic> json) {
    return CartSyncItem(
      productId: json['productId'] as int,
      variationId: json['variationId'] as int,
      productName: json['productName'] as String,
      displayName: json['displayName'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      discountType: json['discountType'] as String,
      lineTotal: (json['lineTotal'] as num).toDouble(),
      productImageUrl: json['productImageUrl'] as String?,
    );
  }
}

/// Cart sync data for transmission
class CartSyncData {
  final List<CartSyncItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final int totalItems;
  final String currencySymbol;
  final String? customerName;

  CartSyncData({
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.totalItems,
    required this.currencySymbol,
    this.customerName,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'totalItems': totalItems,
      'currencySymbol': currencySymbol,
      'customerName': customerName,
    };
  }

  factory CartSyncData.fromJson(Map<String, dynamic> json) {
    return CartSyncData(
      items: (json['items'] as List)
          .map((item) => CartSyncItem.fromJson(Map<String,dynamic>.from(item)))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      totalItems: json['totalItems'] as int,
      currencySymbol: json['currencySymbol'] as String,
      customerName: json['customerName'] as String?,
    );
  }
}

/// Service to sync cart data between POS window and customer window
class OfflineCustomerService {
  static final OfflineCustomerService _instance =
      OfflineCustomerService._internal();

  factory OfflineCustomerService() => _instance;

  OfflineCustomerService._internal();

  WindowMethodChannel offlineCustomerMethodChannel = WindowMethodChannel(
    'com.oman.offline_customer_channel',
    mode: ChannelMode.unidirectional,
  );

  /// Broadcast cart update to customer window (called from POS window)
  Future<void> broadcastCartUpdate(CartSyncData cartData) async {
    try {
      await offlineCustomerMethodChannel.invokeMethod('update_cart', {
        'data': cartData.toJson(),
      });
      Logger.logI('Cart update broadcast to customer window');
    } catch (e) {
      Logger.logE('Failed to broadcast cart update ${e.toString()}', e);
      // Window might be closed, clear reference
    }
  }

  /// Register message handler for customer window (called from customer window)
  Future<void> registerCustomerWindowHandler(
    Function(CartSyncData) onCartUpdate,
  ) async {
    try {
      offlineCustomerMethodChannel.setMethodCallHandler((call) async {
        if (call.method == 'update_cart') {
          try {
            final data = Map<String,dynamic>.from(call.arguments);
            final cartData =
                CartSyncData.fromJson(Map<String,dynamic>.from(data['data']));
            onCartUpdate(cartData);
          } catch (e) {
            Logger.logE('Failed to parse cart update ${e.toString()}', e);
          }
        }
      });
      Logger.logI('Customer window message handler registered');
    } catch (e) {
      Logger.logE('Failed to register customer window handler', e);
    }
  }

  /// Convert POS cart items to sync data
  static CartSyncData convertToSyncData({
    required List<CartItem> cartItems,
    required double subtotal,
    required double discount,
    required double tax,
    required double total,
    required String currencySymbol,
    ContactEntity? customer,
  }) {
    final items = cartItems.map((item) {
      final productName =
          item.product.displayName ?? item.product.productName ?? 'Product';

      return CartSyncItem(
        productId: item.productId,
        variationId: item.variationId,
        productName: productName,
        displayName: item.product.displayName,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        discountAmount: item.discountAmount,
        discountType: item.discountType == DiscountType.percentage
            ? 'percentage'
            : 'fixed',
        lineTotal: item.lineTotal,
        productImageUrl: item.product.productImageUrl,
      );
    }).toList();

    return CartSyncData(
      items: items,
      subtotal: subtotal,
      discount: discount,
      tax: tax,
      total: total,
      totalItems: cartItems.length,
      currencySymbol: currencySymbol,
      customerName: customer?.name,
    );
  }
}
