import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app_config/di.dart';
import 'pos_event.dart';
import 'pos_state.dart';

/// POS page bloc
class PosBloc extends Bloc<PosEvent, PosState> {
  final LocationRepository _locationRepository;
  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  final BrandRepository _brandRepository;
  final CreateSellUseCase _createSellUseCase;
  final SellRepository _sellRepository;
  final BusinessRepository _businessRepository;

  PosBloc({
    required LocationRepository locationRepository,
    required ProductRepository productRepository,
    required CategoryRepository categoryRepository,
    required BrandRepository brandRepository,
    required CreateSellUseCase createSellUseCase,
    required SellRepository sellRepository,
    required BusinessRepository businessRepository,
  })  : _locationRepository = locationRepository,
        _productRepository = productRepository,
        _categoryRepository = categoryRepository,
        _brandRepository = brandRepository,
        _createSellUseCase = createSellUseCase,
        _sellRepository = sellRepository,
        _businessRepository = businessRepository,
        super(PosState.initial()) {
    on<PosInitialize>(_onInitialize);
    on<PosSelectLocation>(_onSelectLocation);
    on<PosSelectCustomer>(_onSelectCustomer);
    on<PosAddToCart>(_onAddToCart);
    on<PosUpdateCartItemQuantity>(_onUpdateCartItemQuantity);
    on<PosRemoveFromCart>(_onRemoveFromCart);
    on<PosClearCart>(_onClearCart);
    on<PosApplyDiscount>(_onApplyDiscount);
    on<PosSetTax>(_onSetTax);
    on<PosSubmitSale>(_onSubmitSale);
    on<PosSubmitCreditSale>(_onSubmitCreditSale);
    on<PosCreateQuotation>(_onCreateQuotation);
    on<PosSuspendSale>(_onSuspendSale);
    on<PosCancelSale>(_onCancelSale);
    on<PosRefreshProducts>(_onRefreshProducts);
    on<PosSearchProducts>(_onSearchProducts);
    on<PosFilterByCategory>(_onFilterByCategory);
    on<PosFilterByBrand>(_onFilterByBrand);
  }

  Future<void> _onInitialize(
    PosInitialize event,
    Emitter<PosState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    try {
      // Get business details for currency symbol
      String currencySymbol = '\$';
      final businessResult = await _businessRepository.getBusinessDetails();
      businessResult.fold(
        onSuccess: (business) {
          currencySymbol = business.currencySymbol ?? '\$';
        },
        onError: (_) {},
      );

      // Get locations
      final locationsResult = await _locationRepository.getLocations();
      List<LocationEntity> locations = [];
      int? defaultLocationId;

      locationsResult.fold(
        onSuccess: (data) {
          locations = data;
          if (data.isNotEmpty) {
            defaultLocationId = data.first.id;
          }
        },
        onError: (failure) {
          emit(state.copyWith(isLoading: false, failure: failure));
          return;
        },
      );

      // Get categories
      final categoriesResult = await _categoryRepository.getCategories();
      List<CategoryEntity> categories = [];
      categoriesResult.fold(
        onSuccess: (data) => categories = data,
        onError: (_) {},
      );

      // Get brands
      final brandsResult = await _brandRepository.getBrands();
      List<BrandEntity> brands = [];
      brandsResult.fold(
        onSuccess: (data) => brands = data,
        onError: (_) {},
      );

      emit(state.copyWith(
        isLoading: false,
        locations: locations,
        selectedLocationId: defaultLocationId,
        categories: categories,
        brands: brands,
        currencySymbol: currencySymbol,
      ));

      // Load products for default location
      if (defaultLocationId != null) {
        add(PosSelectLocation(defaultLocationId!));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  Future<void> _onSelectLocation(
    PosSelectLocation event,
    Emitter<PosState> emit,
  ) async {
    emit(state.copyWith(
      selectedLocationId: event.locationId,
      isLoadingProducts: true,
      cartItems: [], // Clear cart on location change
      clearCustomer: true,
      clearMessages: true,
    ));

    // Load products for location
    final result = await _productRepository.getProducts(
      locationId: event.locationId,
      page: 1,
      perPage: 100,
    );

    result.fold(
      onSuccess: (products) {
        emit(state.copyWith(
          isLoadingProducts: false,
          products: products,
          filteredProducts: products,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoadingProducts: false,
          failure: failure,
        ));
      },
    );
  }

  void _onSelectCustomer(
    PosSelectCustomer event,
    Emitter<PosState> emit,
  ) {
    emit(state.copyWith(
      selectedCustomer: event.customer,
      clearCustomer: event.customer == null,
    ));
  }

  void _onAddToCart(
    PosAddToCart event,
    Emitter<PosState> emit,
  ) {
    final product = event.product;
    // Use productId and variationId from ProductEntity
    final productId = product.productId ?? product.id;
    final variationId = product.variationId ?? 0;
    final updatedCart = List<CartItem>.from(state.cartItems);

    // Check if item already in cart
    final existingIndex = updatedCart.indexWhere(
      (item) =>
          item.productId == productId && item.variationId == variationId,
    );

    if (existingIndex >= 0) {
      // Update quantity
      final existing = updatedCart[existingIndex];
      updatedCart[existingIndex] = existing.copyWith(
        quantity: existing.quantity + event.quantity,
      );
    } else {
      // Add new item
      updatedCart.add(CartItem(
        product: product,
        productId: productId,
        variationId: variationId,
        quantity: event.quantity,
        unitPrice: product.sellPriceIncTax ?? product.defaultSellPrice ?? 0,
        taxId: product.taxId,
      ));
    }

    emit(state.copyWith(cartItems: updatedCart));
  }

  void _onUpdateCartItemQuantity(
    PosUpdateCartItemQuantity event,
    Emitter<PosState> emit,
  ) {
    final updatedCart = List<CartItem>.from(state.cartItems);
    final index = updatedCart.indexWhere(
      (item) =>
          item.productId == event.productId &&
          item.variationId == event.variationId,
    );

    if (index >= 0) {
      if (event.quantity <= 0) {
        updatedCart.removeAt(index);
      } else {
        updatedCart[index] = updatedCart[index].copyWith(
          quantity: event.quantity,
        );
      }
      emit(state.copyWith(cartItems: updatedCart));
    }
  }

  void _onRemoveFromCart(
    PosRemoveFromCart event,
    Emitter<PosState> emit,
  ) {
    final updatedCart = state.cartItems
        .where((item) =>
            !(item.productId == event.productId &&
                item.variationId == event.variationId))
        .toList();
    emit(state.copyWith(cartItems: updatedCart));
  }

  void _onClearCart(
    PosClearCart event,
    Emitter<PosState> emit,
  ) {
    emit(state.copyWith(
      cartItems: [],
      discountAmount: 0,
      discountType: 'fixed',
      taxId: null,
      taxRate: 0,
      clearCustomer: true,
      invoiceType: 'final',
      isQuotation: false,
      isSuspended: false,
    ));
  }

  void _onApplyDiscount(
    PosApplyDiscount event,
    Emitter<PosState> emit,
  ) {
    emit(state.copyWith(
      discountAmount: event.amount,
      discountType: event.type,
    ));
  }

  void _onSetTax(
    PosSetTax event,
    Emitter<PosState> emit,
  ) {
    emit(state.copyWith(
      taxId: event.taxId,
      taxRate: event.taxRate,
    ));
  }

  Future<void> _onSubmitSale(
    PosSubmitSale event,
    Emitter<PosState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(
        failure: ValidationFailure(
            message: 'Please select customer and add items'),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    try {
      // Create sell lines from cart items
      final sellLines = state.cartItems.map((item) {
        return SellLineEntity(
          id: 0,
          productId: item.productId,
          variationId: item.variationId,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          taxRateId: item.taxId ?? state.taxId,
          discountAmount: item.discountAmount,
          discountType: item.discountType,
        );
      }).toList();

      // Create sell entity
      final invoiceNo = _generateInvoiceNo();
      final sell = SellEntity(
        id: 0,
        locationId: state.selectedLocationId,
        contactId: state.selectedCustomer!.id,
        transactionDate: DateTime.now().toIso8601String(),
        invoiceNo: invoiceNo,
        status: 'final',
        taxRateId: state.taxId,
        discountAmount: state.invoiceDiscount,
        discountType: state.discountType,
        invoiceAmount: state.total,
        isQuotation: false,
        isSuspend: false,
        sellLines: sellLines,
      );

      // Create payment for cash sale
      final payment = SellPaymentEntity(
        id: 0,
        sellId: null,
        method: 'cash',
        amount: state.total,
        transactionDate: DateTime.now().toIso8601String(),
      );

      final sellWithPayment = sell.copyWith(payments: [payment]);

      final result = await _createSellUseCase.call(sellWithPayment);

      result.fold(
        onSuccess: (createdSell) {
          emit(state.copyWith(
            isSubmitting: false,
            successMessage: 'Sale completed successfully',
            cartItems: [],
            discountAmount: 0,
            discountType: 'fixed',
            taxId: null,
            taxRate: 0,
            clearCustomer: true,
            invoiceType: 'final',
            isQuotation: false,
            isSuspended: false,
          ));
        },
        onError: (failure) {
          emit(state.copyWith(
            isSubmitting: false,
            failure: failure,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  Future<void> _onSubmitCreditSale(
    PosSubmitCreditSale event,
    Emitter<PosState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(
        failure: ValidationFailure(
            message: 'Please select customer and add items'),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    try {
      final sellLines = state.cartItems.map((item) {
        return SellLineEntity(
          id: 0,
          productId: item.productId,
          variationId: item.variationId,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          taxRateId: item.taxId ?? state.taxId,
          discountAmount: item.discountAmount,
          discountType: item.discountType,
        );
      }).toList();

      final invoiceNo = _generateInvoiceNo();
      final sell = SellEntity(
        id: 0,
        locationId: state.selectedLocationId,
        contactId: state.selectedCustomer!.id,
        transactionDate: DateTime.now().toIso8601String(),
        invoiceNo: invoiceNo,
        status: 'pending',
        taxRateId: state.taxId,
        discountAmount: state.invoiceDiscount,
        discountType: state.discountType,
        invoiceAmount: state.total,
        pendingAmount: state.total,
        isQuotation: false,
        isSuspend: false,
        sellLines: sellLines,
      );

      final result = await _createSellUseCase.call(sell);

      result.fold(
        onSuccess: (_) {
          emit(state.copyWith(
            isSubmitting: false,
            successMessage: 'Credit sale created successfully',
            cartItems: [],
            discountAmount: 0,
            discountType: 'fixed',
            taxId: null,
            taxRate: 0,
            clearCustomer: true,
          ));
        },
        onError: (failure) {
          emit(state.copyWith(
            isSubmitting: false,
            failure: failure,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  Future<void> _onCreateQuotation(
    PosCreateQuotation event,
    Emitter<PosState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(
        failure: ValidationFailure(
            message: 'Please select customer and add items'),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    try {
      // Save quotation locally
      final sellLines = state.cartItems.map((item) {
        return SellLineEntity(
          id: 0,
          productId: item.productId,
          variationId: item.variationId,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          taxRateId: item.taxId ?? state.taxId,
          discountAmount: item.discountAmount,
          discountType: item.discountType,
        );
      }).toList();

      final invoiceNo = _generateInvoiceNo();
      final sell = SellEntity(
        id: 0,
        locationId: state.selectedLocationId,
        contactId: state.selectedCustomer!.id,
        transactionDate: DateTime.now().toIso8601String(),
        invoiceNo: invoiceNo,
        status: 'quotation',
        taxRateId: state.taxId,
        discountAmount: state.invoiceDiscount,
        discountType: state.discountType,
        invoiceAmount: state.total,
        isQuotation: true,
        isSuspend: false,
        sellLines: sellLines,
      );

      // Save locally first
      final localResult = await _sellRepository.saveSellLocally(sell);

      localResult.fold(
        onSuccess: (_) {
          emit(state.copyWith(
            isSubmitting: false,
            successMessage: 'Quotation created successfully',
            cartItems: [],
            clearCustomer: true,
          ));
        },
        onError: (failure) {
          emit(state.copyWith(
            isSubmitting: false,
            failure: failure,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  Future<void> _onSuspendSale(
    PosSuspendSale event,
    Emitter<PosState> emit,
  ) async {
    if (state.cartItems.isEmpty) {
      emit(state.copyWith(
        failure: ValidationFailure(message: 'Cart is empty'),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    try {
      final sellLines = state.cartItems.map((item) {
        return SellLineEntity(
          id: 0,
          productId: item.productId,
          variationId: item.variationId,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          taxRateId: item.taxId ?? state.taxId,
          discountAmount: item.discountAmount,
          discountType: item.discountType,
        );
      }).toList();

      final invoiceNo = _generateInvoiceNo();
      final sell = SellEntity(
        id: 0,
        locationId: state.selectedLocationId,
        contactId: state.selectedCustomer?.id,
        transactionDate: DateTime.now().toIso8601String(),
        invoiceNo: invoiceNo,
        status: 'suspended',
        taxRateId: state.taxId,
        discountAmount: state.invoiceDiscount,
        discountType: state.discountType,
        invoiceAmount: state.total,
        isQuotation: false,
        isSuspend: true,
        sellLines: sellLines,
      );

      // Save locally
      final localResult = await _sellRepository.saveSellLocally(sell);

      localResult.fold(
        onSuccess: (_) {
          emit(state.copyWith(
            isSubmitting: false,
            successMessage: 'Sale suspended successfully',
            cartItems: [],
            clearCustomer: true,
            isSuspended: true,
          ));
        },
        onError: (failure) {
          emit(state.copyWith(
            isSubmitting: false,
            failure: failure,
          ));
        },
      );
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        failure: UnknownFailure(message: e.toString()),
      ));
    }
  }

  void _onCancelSale(
    PosCancelSale event,
    Emitter<PosState> emit,
  ) {
    add(const PosClearCart());
  }

  Future<void> _onRefreshProducts(
    PosRefreshProducts event,
    Emitter<PosState> emit,
  ) async {
    if (state.selectedLocationId == null) return;

    emit(state.copyWith(isLoadingProducts: true, clearMessages: true));

    final result = await _productRepository.syncProducts(state.selectedLocationId!);

    result.fold(
      onSuccess: (_) async {
        // Reload products
        final productsResult = await _productRepository.getProducts(
          locationId: state.selectedLocationId!,
          page: 1,
          perPage: 100,
        );

        productsResult.fold(
          onSuccess: (products) {
            emit(state.copyWith(
              isLoadingProducts: false,
              products: products,
              filteredProducts: _filterProducts(
                products,
                state.searchQuery,
                state.selectedCategoryId,
                state.selectedBrandId,
              ),
              successMessage: 'Products refreshed',
            ));
          },
          onError: (failure) {
            emit(state.copyWith(
              isLoadingProducts: false,
              failure: failure,
            ));
          },
        );
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoadingProducts: false,
          failure: failure,
        ));
      },
    );
  }

  void _onSearchProducts(
    PosSearchProducts event,
    Emitter<PosState> emit,
  ) {
    final filtered = _filterProducts(
      state.products,
      event.query,
      state.selectedCategoryId,
      state.selectedBrandId,
    );

    emit(state.copyWith(
      searchQuery: event.query,
      filteredProducts: filtered,
    ));
  }

  void _onFilterByCategory(
    PosFilterByCategory event,
    Emitter<PosState> emit,
  ) {
    final filtered = _filterProducts(
      state.products,
      state.searchQuery,
      event.categoryId,
      state.selectedBrandId,
    );

    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      clearCategoryId: event.categoryId == null,
      filteredProducts: filtered,
    ));
  }

  void _onFilterByBrand(
    PosFilterByBrand event,
    Emitter<PosState> emit,
  ) {
    final filtered = _filterProducts(
      state.products,
      state.searchQuery,
      state.selectedCategoryId,
      event.brandId,
    );

    emit(state.copyWith(
      selectedBrandId: event.brandId,
      clearBrandId: event.brandId == null,
      filteredProducts: filtered,
    ));
  }

  List<ProductEntity> _filterProducts(
    List<ProductEntity> products,
    String query,
    int? categoryId,
    int? brandId,
  ) {
    return products.where((product) {
      // Search filter
      if (query.isNotEmpty) {
        final name = (product.displayName ?? product.productName ?? '')
            .toLowerCase();
        final sku = (product.sku ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        if (!name.contains(searchLower) && !sku.contains(searchLower)) {
          return false;
        }
      }

      // Category filter
      if (categoryId != null && product.categoryId != categoryId) {
        return false;
      }

      // Brand filter
      if (brandId != null && product.brandId != brandId) {
        return false;
      }

      return true;
    }).toList();
  }

  String _generateInvoiceNo() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch}';
  }
}
