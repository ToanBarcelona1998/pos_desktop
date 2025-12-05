import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/core.dart';
import '../../../core/localization/locale_keys.dart';
import 'pos_event.dart';
import 'pos_state.dart';

/// POS page bloc
class PosBloc extends Bloc<PosEvent, PosState> {
  final LocationRepository _locationRepository;
  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;
  final BrandRepository _brandRepository;
  final ContactRepository _contactRepository;
  final CreateSellUseCase _createSellUseCase;
  final GetSuspendedSellsUseCase _getSuspendedSellsUseCase;
  final DeleteSellUseCase _deleteSellUseCase;
  final BusinessRepository _businessRepository;

  PosBloc({
    required LocationRepository locationRepository,
    required ProductRepository productRepository,
    required CategoryRepository categoryRepository,
    required BrandRepository brandRepository,
    required ContactRepository contactRepository,
    required CreateSellUseCase createSellUseCase,
    required GetSuspendedSellsUseCase getSuspendedSellsUseCase,
    required DeleteSellUseCase deleteSellUseCase,
    required BusinessRepository businessRepository,
  })  : _locationRepository = locationRepository,
        _productRepository = productRepository,
        _categoryRepository = categoryRepository,
        _brandRepository = brandRepository,
        _contactRepository = contactRepository,
        _createSellUseCase = createSellUseCase,
        _getSuspendedSellsUseCase = getSuspendedSellsUseCase,
        _deleteSellUseCase = deleteSellUseCase,
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
    on<PosCreateDraft>(_onCreateDraft);
    on<PosCreateQuotation>(_onCreateQuotation);
    on<PosSuspendSale>(_onSuspendSale);
    on<PosCancelSale>(_onCancelSale);
    on<PosRefreshProducts>(_onRefreshProducts);
    on<PosLoadMoreProducts>(_onLoadMoreProducts);
    on<PosSearchProducts>(_onSearchProducts);
    on<PosFilterByCategory>(_onFilterByCategory);
    on<PosFilterByBrand>(_onFilterByBrand);
    on<PosLoadCustomers>(_onLoadCustomers);
    on<PosSearchCustomers>(_onSearchCustomers);
    on<PosLoadSuspendedSells>(_onLoadSuspendedSells);
    on<PosLoadSuspendedSell>(_onLoadSuspendedSell);
    on<PosDeleteSuspendedSell>(_onDeleteSuspendedSell);
    on<PosClearPrintFlag>(_onClearPrintFlag);
  }

  static const int _perPage = 50;

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

      // Load customers
      add(const PosLoadCustomers());
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
      currentPage: 1,
      hasMore: true,
    ));

    // Load products for location (first page)
    final result = await _productRepository.getProducts(
      locationId: event.locationId,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (products) {
        final filtered = _filterProducts(
          products,
          state.searchQuery,
          state.selectedCategoryId,
          state.selectedBrandId,
        );
        emit(state.copyWith(
          isLoadingProducts: false,
          products: products,
          filteredProducts: filtered,
          hasMore: products.length >= _perPage,
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
      discountType: DiscountType.fixed,
      taxId: null,
      taxRate: 0,
      clearCustomer: true,
      invoiceType: InvoiceType.final_,
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
            message: LocaleKeys.pleaseSelectCustomerAndAddItems),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    try {
      // Create sell lines from cart items (like old code)
      final sellLines = state.cartItems.map((item) {
        return SellLineEntity(
          id: 0,
          productId: item.productId,
          variationId: item.variationId,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          taxRateId: item.taxId ?? state.taxId,
          discountAmount: item.discountAmount,
          discountType: item.discountType.value,
        );
      }).toList();

      // Calculate adjusted invoice amount (like old code: invoiceAmount - discount)
      // Note: old code uses invoiceAmount (subtotal) before tax, then subtracts discount
      final adjustedInvoiceAmount = state.adjustedInvoiceAmount;

      // Determine status (like old code: isCredit ? 'pending' : invoiceType)
      final saleStatus = event.isCredit
          ? SellStatus.pending
          : state.invoiceType.toSellStatus();

      // Create sell entity - use state values, no hardcoded values
      final invoiceNo = _generateInvoiceNo();
      final sell = SellEntity(
        id: 0,
        locationId: state.selectedLocationId,
        contactId: state.selectedCustomer!.id,
        transactionDate: DateTime.now().toIso8601String(),
        invoiceNo: invoiceNo,
        status: saleStatus.value, // Dynamic: isCredit ? 'pending' : invoiceType
        taxRateId: state.taxId,
        discountAmount: state.discountAmount, // Use raw discount amount
        discountType: state.discountType.value,
        invoiceAmount: adjustedInvoiceAmount, // Use adjusted amount (after discount, before tax)
        pendingAmount: event.isCredit ? adjustedInvoiceAmount : 0.0, // Like old code
        isQuotation: state.isQuotation, // Use state value
        isSuspend: state.isSuspended, // Use state value
        sellLines: sellLines,
      );

      // Create payment only if not quotation and not suspended (like old code)
      final List<SellPaymentEntity> payments = [];
      if (!state.isQuotation && !state.isSuspended) {
        // Determine payment method (like old code: isCredit ? 'card' : 'cash')
        final paymentMethod = event.paymentMethod ??
            (event.isCredit ? PaymentMethod.card : PaymentMethod.cash);

        // Payment amount (like old code: isCredit ? 0 : adjustedInvoiceAmount)
        final paymentAmount = event.isCredit ? 0.0 : adjustedInvoiceAmount;

        payments.add(SellPaymentEntity(
          id: 0,
          sellId: null,
          method: paymentMethod.value, // Dynamic: based on isCredit or provided
          amount: paymentAmount, // Dynamic: isCredit ? 0 : adjustedInvoiceAmount
          transactionDate: DateTime.now().toIso8601String(),
        ));
      }

      final sellWithPayment = sell.copyWith(payments: payments);

      final result = await _createSellUseCase.call(sellWithPayment);

      result.fold(
        onSuccess: (createdSell) {
          print('create sell id ${createdSell.id} , url ${createdSell.invoiceUrl}');
          // Only print if not suspended and printInvoice is true
          final shouldPrint = event.printInvoice && !state.isSuspended;
          
          emit(state.copyWith(
            isSubmitting: false,
            successMessage: event.isCredit
                ? LocaleKeys.creditSaleCreatedSuccessfully
                : (state.isQuotation
                    ? LocaleKeys.quotationCreatedSuccessfully
                    : (state.isSuspended
                        ? LocaleKeys.saleSuspendedSuccessfully
                        : LocaleKeys.saleCompletedSuccessfully)),
            createdSellId: createdSell.id, // Store created sell ID for printing
            shouldPrintInvoice: shouldPrint, // Flag to trigger printing
            cartItems: [],
            discountAmount: 0,
            discountType: DiscountType.fixed,
            taxId: null,
            taxRate: 0,
            clearCustomer: true,
            invoiceType: InvoiceType.final_,
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
    // Credit sale is now handled by PosSubmitSale with isCredit=true
    // This method redirects to the unified submit method
    add(PosSubmitSale(isCredit: true));
  }

  Future<void> _onCreateDraft(
    PosCreateDraft event,
    Emitter<PosState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(
        failure: ValidationFailure(
            message: LocaleKeys.pleaseSelectCustomerAndAddItems),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    try {
      // Create sell lines from cart items (like old code)
      final sellLines = state.cartItems.map((item) {
        return SellLineEntity(
          id: 0,
          productId: item.productId,
          variationId: item.variationId,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          taxRateId: item.taxId ?? state.taxId,
          discountAmount: item.discountAmount,
          discountType: item.discountType.value,
        );
      }).toList();

      // Calculate adjusted invoice amount (like old code)
      final adjustedInvoiceAmount = state.adjustedInvoiceAmount;

      // Create sell entity - draft uses 'draft' status
      final invoiceNo = _generateInvoiceNo();
      final sell = SellEntity(
        id: 0,
        locationId: state.selectedLocationId,
        contactId: state.selectedCustomer!.id,
        transactionDate: DateTime.now().toIso8601String(),
        invoiceNo: invoiceNo,
        status: SellStatus.draft.value, // Draft always uses 'draft' status
        taxRateId: state.taxId,
        discountAmount: state.discountAmount, // Use raw discount amount
        discountType: state.discountType.value,
        invoiceAmount: adjustedInvoiceAmount, // Use adjusted amount (like old code)
        isQuotation: false, // Draft is not a quotation
        isSuspend: false, // Draft is not suspended
        sellLines: sellLines,
      );

      // No payment for drafts (like old code: !isQuotation && !isSuspend)

      // Use use case to create sell (handles server-first logic)
      final result = await _createSellUseCase.call(sell);

      result.fold(
        onSuccess: (_) {
          emit(state.copyWith(
            isSubmitting: false,
            successMessage: LocaleKeys.draftCreatedSuccessfully,
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

  Future<void> _onCreateQuotation(
    PosCreateQuotation event,
    Emitter<PosState> emit,
  ) async {
    if (!state.canSubmit) {
      emit(state.copyWith(
        failure: ValidationFailure(
            message: LocaleKeys.pleaseSelectCustomerAndAddItems),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    try {
      // Create sell lines from cart items (like old code)
      final sellLines = state.cartItems.map((item) {
        return SellLineEntity(
          id: 0,
          productId: item.productId,
          variationId: item.variationId,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          taxRateId: item.taxId ?? state.taxId,
          discountAmount: item.discountAmount,
          discountType: item.discountType.value,
        );
      }).toList();

      // Calculate adjusted invoice amount (like old code)
      final adjustedInvoiceAmount = state.adjustedInvoiceAmount;

      // Create sell entity - quotation uses 'quotation' status
      final invoiceNo = _generateInvoiceNo();
      final sell = SellEntity(
        id: 0,
        locationId: state.selectedLocationId,
        contactId: state.selectedCustomer!.id,
        transactionDate: DateTime.now().toIso8601String(),
        invoiceNo: invoiceNo,
        status: SellStatus.quotation.value, // Quotation always uses 'quotation' status
        taxRateId: state.taxId,
        discountAmount: state.discountAmount, // Use raw discount amount
        discountType: state.discountType.value,
        invoiceAmount: adjustedInvoiceAmount, // Use adjusted amount (like old code)
        isQuotation: true, // Quotation always has isQuotation = true
        isSuspend: state.isSuspended, // Use state value
        sellLines: sellLines,
      );

      // No payment for quotations (like old code: !isQuotation && !isSuspend)

      // Use use case to create sell (handles server-first logic)
      final result = await _createSellUseCase.call(sell);

      result.fold(
        onSuccess: (_) {
          emit(state.copyWith(
            isSubmitting: false,
            successMessage: LocaleKeys.quotationCreatedSuccessfully,
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
        failure: ValidationFailure(message: LocaleKeys.cartIsEmpty),
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    try {
      // Create sell lines from cart items (like old code)
      final sellLines = state.cartItems.map((item) {
        return SellLineEntity(
          id: 0,
          productId: item.productId,
          variationId: item.variationId,
          quantity: item.quantity.toDouble(),
          unitPrice: item.unitPrice,
          taxRateId: item.taxId ?? state.taxId,
          discountAmount: item.discountAmount,
          discountType: item.discountType.value,
        );
      }).toList();

      // Calculate adjusted invoice amount (like old code)
      final adjustedInvoiceAmount = state.adjustedInvoiceAmount;

      // Create sell entity - suspended uses 'suspended' status
      final invoiceNo = _generateInvoiceNo();
      final sell = SellEntity(
        id: 0,
        locationId: state.selectedLocationId,
        contactId: state.selectedCustomer?.id,
        transactionDate: DateTime.now().toIso8601String(),
        invoiceNo: invoiceNo,
        status: SellStatus.suspended.value, // Suspended sale always uses 'suspended' status
        taxRateId: state.taxId,
        discountAmount: state.discountAmount, // Use raw discount amount
        discountType: state.discountType.value,
        invoiceAmount: adjustedInvoiceAmount, // Use adjusted amount (like old code)
        isQuotation: state.isQuotation, // Use state value
        isSuspend: true, // Suspended sale always has isSuspend = true
        sellLines: sellLines,
      );

      // No payment for suspended sales (like old code: !isQuotation && !isSuspend)

      // Use use case to create sell (handles server-first logic)
      final result = await _createSellUseCase.call(sell);

      result.fold(
        onSuccess: (_) {
          emit(state.copyWith(
            isSubmitting: false,
            successMessage: LocaleKeys.saleSuspendedSuccessfully,
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

    emit(state.copyWith(
      isLoadingProducts: true,
      clearMessages: true,
      currentPage: 1,
    ));

    // Sync products first
    await _productRepository.syncProducts(state.selectedLocationId!);

    // Reload products from first page
    final result = await _productRepository.getProducts(
      locationId: state.selectedLocationId!,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (products) {
        final filtered = _filterProducts(
          products,
          state.searchQuery,
          state.selectedCategoryId,
          state.selectedBrandId,
        );
        emit(state.copyWith(
          isLoadingProducts: false,
          products: products,
          filteredProducts: filtered,
          currentPage: 1,
          hasMore: products.length >= _perPage,
          successMessage: LocaleKeys.syncCompletedSuccessfully,
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

  Future<void> _onLoadMoreProducts(
    PosLoadMoreProducts event,
    Emitter<PosState> emit,
  ) async {
    if (state.selectedLocationId == null ||
        !state.hasMore ||
        state.isLoadingMore) {
      return;
    }

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.currentPage + 1;
    final result = await _productRepository.getProducts(
      locationId: state.selectedLocationId!,
      page: nextPage,
      perPage: _perPage,
    );

    result.fold(
      onSuccess: (newProducts) {
        if (newProducts.isEmpty) {
          emit(state.copyWith(
            isLoadingMore: false,
            hasMore: false,
          ));
          return;
        }

        final allProducts = [...state.products, ...newProducts];
        final filtered = _filterProducts(
          allProducts,
          state.searchQuery,
          state.selectedCategoryId,
          state.selectedBrandId,
        );

        emit(state.copyWith(
          isLoadingMore: false,
          products: allProducts,
          filteredProducts: filtered,
          currentPage: nextPage,
          hasMore: newProducts.length >= _perPage,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoadingMore: false,
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
        final sku = (product.subSku ?? product.sku ?? '').toLowerCase();
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

  Future<void> _onLoadCustomers(
    PosLoadCustomers event,
    Emitter<PosState> emit,
  ) async {
    emit(state.copyWith(isLoadingCustomers: true));

    final result = await _contactRepository.getContacts(type: ContactType.customer.value);

    result.fold(
      onSuccess: (customers) {
        emit(state.copyWith(
          customers: customers,
          isLoadingCustomers: false,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoadingCustomers: false,
          failure: failure,
        ));
      },
    );
  }

  void _onSearchCustomers(
    PosSearchCustomers event,
    Emitter<PosState> emit,
  ) {
    emit(state.copyWith(customerSearchQuery: event.query));
  }

  Future<void> _onLoadSuspendedSells(
    PosLoadSuspendedSells event,
    Emitter<PosState> emit,
  ) async {
    emit(state.copyWith(isLoadingSuspendedSells: true));

    final result = await _getSuspendedSellsUseCase.call();

    result.fold(
      onSuccess: (sells) {
        emit(state.copyWith(
          suspendedSells: sells,
          isLoadingSuspendedSells: false,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoadingSuspendedSells: false,
          failure: failure,
        ));
      },
    );
  }

  Future<void> _onLoadSuspendedSell(
    PosLoadSuspendedSell event,
    Emitter<PosState> emit,
  ) async {
    final sell = event.sell;

    // Load customer if available
    ContactEntity? customer;
    if (sell.contactId != null) {
      final customerResult = await _contactRepository.getContactById(sell.contactId!);
      customerResult.fold(
        onSuccess: (c) => customer = c,
        onError: (_) {},
      );
    }

    // Load products and create cart items from sell lines
    final cartItems = <CartItem>[];
    if (sell.sellLines.isNotEmpty) {
      // Get all products for the location to find product details
      final productsResult = await _productRepository.getProducts(
        locationId: sell.locationId!,
        page: 1,
        perPage: 1000, // Get all products to find matches
      );

      productsResult.fold(
        onSuccess: (products) {
          for (final line in sell.sellLines) {
            // Find matching product
            final product = products.firstWhere(
              (p) => (p.productId ?? p.id) == line.productId &&
                  (p.variationId ?? 0) == line.variationId,
              orElse: () => products.first, // Fallback, should not happen
            );

            cartItems.add(CartItem(
              product: product,
              productId: line.productId!,
              variationId: line.variationId!,
              quantity: line.quantity!.toInt(),
              unitPrice: line.unitPrice!,
              discountAmount: line.discountAmount ?? 0,
              discountType: DiscountTypeExtension.fromString(line.discountType) ?? DiscountType.fixed,
              taxId: line.taxRateId,
            ));
          }
        },
        onError: (_) {},
      );
    }

    // Set discount and tax
    final discountAmount = sell.discountAmount ?? 0;
    final discountType = DiscountTypeExtension.fromString(sell.discountType) ?? DiscountType.fixed;
    final taxId = sell.taxRateId;

    // Get tax rate if taxId is available
    double taxRate = 0;
    if (taxId != null && taxId != 0) {
      // Try to get tax rate from repository (if available)
      // For now, we'll need to calculate from the sell amount
    }

    // Determine invoice type from sell status
    final invoiceType = SellStatusExtension.fromString(sell.status) != null
        ? (SellStatusExtension.fromString(sell.status) == SellStatus.suspended
            ? InvoiceType.suspended
            : InvoiceType.final_)
        : InvoiceType.suspended;

    emit(state.copyWith(
      selectedCustomer: customer,
      cartItems: cartItems,
      discountAmount: discountAmount,
      discountType: discountType,
      taxId: taxId,
      taxRate: taxRate,
      isSuspended: true,
      invoiceType: invoiceType,
      successMessage: LocaleKeys.suspendedSaleLoaded,
    ));
  }

  Future<void> _onDeleteSuspendedSell(
    PosDeleteSuspendedSell event,
    Emitter<PosState> emit,
  ) async {
    final result = await _deleteSellUseCase.call(event.sellId);

    result.fold(
      onSuccess: (_) {
        // Reload suspended sells
        add(const PosLoadSuspendedSells());
        emit(state.copyWith(
          successMessage: LocaleKeys.suspendedSaleDeleted,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(failure: failure));
      },
    );
  }

  void _onClearPrintFlag(
    PosClearPrintFlag event,
    Emitter<PosState> emit,
  ) {
    emit(state.copyWith(shouldPrintInvoice: false));
  }

  String _generateInvoiceNo() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.millisecondsSinceEpoch}';
  }
}
