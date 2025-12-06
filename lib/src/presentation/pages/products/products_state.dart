import 'package:domain/domain.dart';

/// Products page state
class ProductsState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSyncing;
  final List<ProductEntity> products;
  final String searchQuery;
  final int? selectedCategoryId;
  final int? selectedBrandId;
  final int selectedLocationId;
  final int currentPage;
  final bool hasMore;
  final Failure? failure;

  const ProductsState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSyncing = false,
    this.products = const [],
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedBrandId,
    this.selectedLocationId = 0,
    this.currentPage = 1,
    this.hasMore = true,
    this.failure,
  });

  factory ProductsState.initial({required int locationId}) => ProductsState(
        isLoading: true,
        selectedLocationId: locationId,
      );

  int get totalProducts => products.length;

  ProductsState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSyncing,
    List<ProductEntity>? products,
    String? searchQuery,
    int? selectedCategoryId,
    int? selectedBrandId,
    int? selectedLocationId,
    int? currentPage,
    bool? hasMore,
    Failure? failure,
    bool clearCategoryId = false,
    bool clearBrandId = false,
    bool clearFailure = false,
  }) {
    return ProductsState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSyncing: isSyncing ?? this.isSyncing,
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId: clearCategoryId ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedBrandId: clearBrandId ? null : (selectedBrandId ?? this.selectedBrandId),
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}













