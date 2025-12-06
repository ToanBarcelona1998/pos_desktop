import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'products_event.dart';
import 'products_state.dart';

/// Products page bloc
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final ProductRepository _productRepository;
  final GetProductsUseCase _getProductsUseCase;
  final SearchProductsUseCase _searchProductsUseCase;

  static const int _perPage = 20;

  ProductsBloc({
    required int initialLocationId,
    required ProductRepository productRepository,
    required GetProductsUseCase getProductsUseCase,
    required SearchProductsUseCase searchProductsUseCase,
  })  : _productRepository = productRepository,
        _getProductsUseCase = getProductsUseCase,
        _searchProductsUseCase = searchProductsUseCase,
        super(ProductsState.initial(locationId: initialLocationId)) {
    on<ProductsLoad>(_onLoad);
    on<ProductsLoadMore>(_onLoadMore);
    on<ProductsRefresh>(_onRefresh);
    on<ProductsSearch>(_onSearch);
    on<ProductsFilterByCategory>(_onFilterByCategory);
    on<ProductsFilterByBrand>(_onFilterByBrand);
    on<ProductsChangeLocation>(_onChangeLocation);
    on<ProductsSync>(_onSync);
  }

  Future<void> _onLoad(
    ProductsLoad event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      clearFailure: true,
      selectedLocationId: event.locationId,
      currentPage: 1,
    ));

    final result = await _getProductsUseCase.call(GetProductsParams(
      locationId: event.locationId,
      page: 1,
      perPage: _perPage,
    ));

    result.fold(
      onSuccess: (products) {
        emit(state.copyWith(
          isLoading: false,
          products: products,
          hasMore: products.length >= _perPage,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
      },
    );
  }

  Future<void> _onLoadMore(
    ProductsLoadMore event,
    Emitter<ProductsState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.currentPage + 1;

    final result = await _getProductsUseCase.call(GetProductsParams(
      locationId: state.selectedLocationId,
      page: nextPage,
      perPage: _perPage,
    ));

    result.fold(
      onSuccess: (products) {
        emit(state.copyWith(
          isLoadingMore: false,
          products: [...state.products, ...products],
          currentPage: nextPage,
          hasMore: products.length >= _perPage,
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

  Future<void> _onRefresh(
    ProductsRefresh event,
    Emitter<ProductsState> emit,
  ) async {
    add(ProductsLoad(locationId: state.selectedLocationId));
  }

  Future<void> _onSearch(
    ProductsSearch event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(
      isLoading: true,
      searchQuery: event.query,
      clearFailure: true,
    ));

    if (event.query.isEmpty) {
      add(ProductsLoad(locationId: state.selectedLocationId));
      return;
    }

    final result = await _searchProductsUseCase.call(SearchProductsParams(
      locationId: state.selectedLocationId,
      query: event.query,
      categoryId: state.selectedCategoryId,
      brandId: state.selectedBrandId,
    ));

    result.fold(
      onSuccess: (products) {
        emit(state.copyWith(
          isLoading: false,
          products: products,
          hasMore: false,
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isLoading: false,
          failure: failure,
        ));
      },
    );
  }

  Future<void> _onFilterByCategory(
    ProductsFilterByCategory event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(
      selectedCategoryId: event.categoryId,
      clearCategoryId: event.categoryId == null,
    ));

    // Re-search with new filter
    if (state.searchQuery.isNotEmpty) {
      add(ProductsSearch(state.searchQuery));
    } else {
      add(ProductsLoad(locationId: state.selectedLocationId));
    }
  }

  Future<void> _onFilterByBrand(
    ProductsFilterByBrand event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(
      selectedBrandId: event.brandId,
      clearBrandId: event.brandId == null,
    ));

    // Re-search with new filter
    if (state.searchQuery.isNotEmpty) {
      add(ProductsSearch(state.searchQuery));
    } else {
      add(ProductsLoad(locationId: state.selectedLocationId));
    }
  }

  Future<void> _onChangeLocation(
    ProductsChangeLocation event,
    Emitter<ProductsState> emit,
  ) async {
    add(ProductsLoad(locationId: event.locationId));
  }

  Future<void> _onSync(
    ProductsSync event,
    Emitter<ProductsState> emit,
  ) async {
    emit(state.copyWith(isSyncing: true, clearFailure: true));

    final result = await _productRepository.syncProducts(state.selectedLocationId);

    result.fold(
      onSuccess: (_) {
        emit(state.copyWith(isSyncing: false));
        add(const ProductsRefresh());
      },
      onError: (failure) {
        emit(state.copyWith(
          isSyncing: false,
          failure: failure,
        ));
      },
    );
  }
}













