import 'package:domain/domain.dart';

/// Brands page state
class BrandsState {
  final bool isLoading;
  final bool isSubmitting;
  final List<BrandEntity> brands;
  final List<BrandEntity> filteredBrands;
  final String searchQuery;
  final Failure? failure;
  final String? successMessage;

  const BrandsState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.brands = const [],
    this.filteredBrands = const [],
    this.searchQuery = '',
    this.failure,
    this.successMessage,
  });

  factory BrandsState.initial() => const BrandsState(isLoading: true);

  int get totalBrands => brands.length;

  BrandsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<BrandEntity>? brands,
    List<BrandEntity>? filteredBrands,
    String? searchQuery,
    Failure? failure,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return BrandsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      brands: brands ?? this.brands,
      filteredBrands: filteredBrands ?? this.filteredBrands,
      searchQuery: searchQuery ?? this.searchQuery,
      failure: clearMessages ? null : (failure ?? this.failure),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}











