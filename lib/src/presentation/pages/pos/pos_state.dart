import 'package:domain/domain.dart';
import 'package:pos_final/src/core/core.dart';

/// Cart item model
class CartItem {
  final ProductEntity product;
  final int productId;
  final int variationId;
  int quantity;
  double unitPrice;
  double discountAmount;
  DiscountType discountType;
  int? taxId;

  CartItem({
    required this.product,
    required this.productId,
    required this.variationId,
    this.quantity = 1,
    required this.unitPrice,
    this.discountAmount = 0,
    this.discountType = DiscountType.fixed,
    this.taxId,
  });

  double get lineTotal {
    final discount = discountType == DiscountType.percentage
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
    DiscountType? discountType,
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
  final List<ContactEntity> customers;
  final bool isLoadingCustomers;
  final String customerSearchQuery;

  // Products
  final List<ProductEntity> products;
  final List<ProductEntity> filteredProducts;
  final String searchQuery;
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final List<CategoryEntity> categories;
  final List<BrandEntity> brands;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  // Cart
  final List<CartItem> cartItems;
  final double discountAmount;
  final DiscountType discountType;
  final int? taxId;
  final double taxRate;

  // Invoice
  final InvoiceType invoiceType;
  final bool isQuotation;
  final bool isSuspended;

  // Suspended Sells
  final List<SellEntity> suspendedSells;
  final bool isLoadingSuspendedSells;

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
    this.customers = const [],
    this.isLoadingCustomers = false,
    this.customerSearchQuery = '',
    this.products = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedBrandId,
    this.categories = const [],
    this.brands = const [],
    this.currentPage = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.cartItems = const [],
    this.discountAmount = 0,
    this.discountType = DiscountType.fixed,
    this.taxId,
    this.taxRate = 0,
    this.invoiceType = InvoiceType.final_,
    this.isQuotation = false,
    this.isSuspended = false,
    this.suspendedSells = const [],
    this.isLoadingSuspendedSells = false,
    this.currencySymbol = '\$',
    this.failure,
    this.successMessage,
  });

  factory PosState.initial() => const PosState(isLoading: true);

  /// Calculate subtotal (before discount and tax)
  double get subtotal => cartItems.fold(0, (sum, item) => sum + item.lineTotal);

  /// Calculate discount on invoice
  double get invoiceDiscount {
    if (discountType == DiscountType.percentage) {
      return subtotal * discountAmount / 100;
    }
    return discountAmount;
  }

  /// Calculate tax amount
  double get taxAmount => (subtotal - invoiceDiscount) * taxRate / 100;

  /// Calculate total (includes tax)
  double get total => subtotal - invoiceDiscount + taxAmount;

  /// Calculate adjusted invoice amount
  /// Old POS logic: adjustedInvoiceAmount = invoiceAmount - discount
  /// Where invoiceAmount is the total (subtotal + tax)
  /// So: adjustedInvoiceAmount = total - discount
  double get adjustedInvoiceAmount {
    if (discountType == DiscountType.percentage) {
      return total - (total * discountAmount / 100);
    }
    return total - discountAmount;
  }

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
    List<ContactEntity>? customers,
    bool? isLoadingCustomers,
    String? customerSearchQuery,
    List<ProductEntity>? products,
    List<ProductEntity>? filteredProducts,
    String? searchQuery,
    int? selectedCategoryId,
    int? selectedBrandId,
    List<CategoryEntity>? categories,
    List<BrandEntity>? brands,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    List<CartItem>? cartItems,
    double? discountAmount,
    DiscountType? discountType,
    int? taxId,
    double? taxRate,
    InvoiceType? invoiceType,
    bool? isQuotation,
    bool? isSuspended,
    List<SellEntity>? suspendedSells,
    bool? isLoadingSuspendedSells,
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
      customers: customers ?? this.customers,
      isLoadingCustomers: isLoadingCustomers ?? this.isLoadingCustomers,
      customerSearchQuery: customerSearchQuery ?? this.customerSearchQuery,
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
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      cartItems: cartItems ?? this.cartItems,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      taxId: taxId ?? this.taxId,
      taxRate: taxRate ?? this.taxRate,
      invoiceType: invoiceType ?? this.invoiceType,
      isQuotation: isQuotation ?? this.isQuotation,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedSells: suspendedSells ?? this.suspendedSells,
      isLoadingSuspendedSells: isLoadingSuspendedSells ?? this.isLoadingSuspendedSells,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      failure: clearMessages ? null : (failure ?? this.failure),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}
