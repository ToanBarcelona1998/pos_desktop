import 'package:domain/domain.dart';

/// Cart item model
class CartItem {
  final ProductEntity product;
  final int productId;
  final int variationId;
  int quantity;
  double unitPrice;
  double discountAmount;
  String discountType;
  int? taxId;

  CartItem({
    required this.product,
    required this.productId,
    required this.variationId,
    this.quantity = 1,
    required this.unitPrice,
    this.discountAmount = 0,
    this.discountType = 'fixed',
    this.taxId,
  });

  double get lineTotal {
    final discount = discountType == 'percentage'
        ? unitPrice * quantity * discountAmount / 100
        : discountAmount;
    return (unitPrice * quantity) - discount;
  }

  CartItem copyWith({
    ProductEntity? product,
    int? productId,
    int? variationId,
    int? quantity,
    double? unitPrice,
    double? discountAmount,
    String? discountType,
    int? taxId,
  }) {
    return CartItem(
      product: product ?? this.product,
      productId: productId ?? this.productId,
      variationId: variationId ?? this.variationId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      taxId: taxId ?? this.taxId,
    );
  }
}

/// POS page state
class PosState {
  final bool isLoading;
  final bool isSubmitting;
  final bool isLoadingProducts;

  // Location
  final List<LocationEntity> locations;
  final int? selectedLocationId;

  // Customer
  final ContactEntity? selectedCustomer;

  // Products
  final List<ProductEntity> products;
  final List<ProductEntity> filteredProducts;
  final String searchQuery;
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final List<CategoryEntity> categories;
  final List<BrandEntity> brands;

  // Cart
  final List<CartItem> cartItems;
  final double discountAmount;
  final String discountType;
  final int? taxId;
  final double taxRate;

  // Invoice
  final String invoiceType; // 'final', 'quotation', 'suspended'
  final bool isQuotation;
  final bool isSuspended;

  // Currency
  final String currencySymbol;

  // Feedback
  final Failure? failure;
  final String? successMessage;

  const PosState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.isLoadingProducts = false,
    this.locations = const [],
    this.selectedLocationId,
    this.selectedCustomer,
    this.products = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedBrandId,
    this.categories = const [],
    this.brands = const [],
    this.cartItems = const [],
    this.discountAmount = 0,
    this.discountType = 'fixed',
    this.taxId,
    this.taxRate = 0,
    this.invoiceType = 'final',
    this.isQuotation = false,
    this.isSuspended = false,
    this.currencySymbol = '\$',
    this.failure,
    this.successMessage,
  });

  factory PosState.initial() => const PosState(isLoading: true);

  /// Calculate subtotal (before discount and tax)
  double get subtotal => cartItems.fold(0, (sum, item) => sum + item.lineTotal);

  /// Calculate discount on invoice
  double get invoiceDiscount {
    if (discountType == 'percentage') {
      return subtotal * discountAmount / 100;
    }
    return discountAmount;
  }

  /// Calculate tax amount
  double get taxAmount => (subtotal - invoiceDiscount) * taxRate / 100;

  /// Calculate total
  double get total => subtotal - invoiceDiscount + taxAmount;

  /// Get cart item count
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Check if cart is empty
  bool get isCartEmpty => cartItems.isEmpty;

  /// Check if can submit
  bool get canSubmit =>
      selectedCustomer != null &&
      selectedLocationId != null &&
      cartItems.isNotEmpty;

  PosState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    bool? isLoadingProducts,
    List<LocationEntity>? locations,
    int? selectedLocationId,
    ContactEntity? selectedCustomer,
    List<ProductEntity>? products,
    List<ProductEntity>? filteredProducts,
    String? searchQuery,
    int? selectedCategoryId,
    int? selectedBrandId,
    List<CategoryEntity>? categories,
    List<BrandEntity>? brands,
    List<CartItem>? cartItems,
    double? discountAmount,
    String? discountType,
    int? taxId,
    double? taxRate,
    String? invoiceType,
    bool? isQuotation,
    bool? isSuspended,
    String? currencySymbol,
    Failure? failure,
    String? successMessage,
    bool clearCustomer = false,
    bool clearCategoryId = false,
    bool clearBrandId = false,
    bool clearMessages = false,
  }) {
    return PosState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      locations: locations ?? this.locations,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      selectedCustomer:
          clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategoryId
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedBrandId:
          clearBrandId ? null : (selectedBrandId ?? this.selectedBrandId),
      categories: categories ?? this.categories,
      brands: brands ?? this.brands,
      cartItems: cartItems ?? this.cartItems,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      taxId: taxId ?? this.taxId,
      taxRate: taxRate ?? this.taxRate,
      invoiceType: invoiceType ?? this.invoiceType,
      isQuotation: isQuotation ?? this.isQuotation,
      isSuspended: isSuspended ?? this.isSuspended,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      failure: clearMessages ? null : (failure ?? this.failure),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}
