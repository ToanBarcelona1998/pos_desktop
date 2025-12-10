import 'package:domain/domain.dart';
import 'package:pos_final/src/core/core.dart';

/// POS page status enum
enum PosStatus {
  /// Initial state
  initial,
  
  /// Loading initial data
  loading,
  
  /// Submitting sale
  submitting,
  
  /// Loading products
  loadingProducts,
  
  /// Loading customers
  loadingCustomers,
  
  /// Loading more products (pagination)
  loadingMore,
  
  /// Loading suspended sells
  loadingSuspendedSells,
  
  /// Success state
  success,
  
  /// Error state
  error,
  
  /// Idle/ready state
  idle,
}

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
  final PosStatus status;

  // Location
  final List<LocationEntity> locations;
  final int? selectedLocationId;

  // Customer
  final ContactEntity? selectedCustomer;
  final List<ContactEntity> customers;
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

  // Currency
  final String currencySymbol;

  // Feedback
  final String? errorMessage;
  final String? successMessage;
  final int? createdSellId; // ID of the last created sell (for printing)
  final bool shouldPrintInvoice; // Flag to trigger invoice printing

  const PosState({
    this.status = PosStatus.idle,
    this.locations = const [],
    this.selectedLocationId,
    this.selectedCustomer,
    this.customers = const [],
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
    this.cartItems = const [],
    this.discountAmount = 0,
    this.discountType = DiscountType.fixed,
    this.taxId,
    this.taxRate = 0,
    this.invoiceType = InvoiceType.final_,
    this.isQuotation = false,
    this.isSuspended = false,
    this.suspendedSells = const [],
    this.currencySymbol = '\$',
    this.errorMessage,
    this.successMessage,
    this.createdSellId,
    this.shouldPrintInvoice = false,
  });

  factory PosState.initial() => const PosState(status: PosStatus.initial);

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

  bool get isLoadingMore => status == PosStatus.loadingMore;

  PosState copyWith({
    PosStatus? status,
    List<LocationEntity>? locations,
    int? selectedLocationId,
    ContactEntity? selectedCustomer,
    List<ContactEntity>? customers,
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
    List<CartItem>? cartItems,
    double? discountAmount,
    DiscountType? discountType,
    int? taxId,
    double? taxRate,
    InvoiceType? invoiceType,
    bool? isQuotation,
    bool? isSuspended,
    List<SellEntity>? suspendedSells,
    String? currencySymbol,
    String? errorMessage,
    String? successMessage,
    int? createdSellId,
    bool? shouldPrintInvoice,
    bool clearCustomer = false,
    bool clearCategoryId = false,
    bool clearBrandId = false,
    bool clearMessages = false,
  }) {
    return PosState(
      status: status ?? this.status,
      locations: locations ?? this.locations,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      selectedCustomer:
          clearCustomer ? null : (selectedCustomer ?? this.selectedCustomer),
      customers: customers ?? this.customers,
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
      cartItems: cartItems ?? this.cartItems,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      taxId: taxId ?? this.taxId,
      taxRate: taxRate ?? this.taxRate,
      invoiceType: invoiceType ?? this.invoiceType,
      isQuotation: isQuotation ?? this.isQuotation,
      isSuspended: isSuspended ?? this.isSuspended,
      suspendedSells: suspendedSells ?? this.suspendedSells,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearMessages ? null : (successMessage ?? this.successMessage),
      createdSellId: createdSellId ?? this.createdSellId,
      shouldPrintInvoice: shouldPrintInvoice ?? this.shouldPrintInvoice,
    );
  }
}
