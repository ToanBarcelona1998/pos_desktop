import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'brand_list_state.dart';

/// Cubit for managing brand list
class BrandListCubit extends Cubit<BrandListState> {
  final GetBrandsUseCase _getBrandsUseCase;
  final CreateBrandUseCase _createBrandUseCase;
  final DeleteBrandUseCase _deleteBrandUseCase;

  BrandListCubit({
    required GetBrandsUseCase getBrandsUseCase,
    required CreateBrandUseCase createBrandUseCase,
    required DeleteBrandUseCase deleteBrandUseCase,
  })  : _getBrandsUseCase = getBrandsUseCase,
        _createBrandUseCase = createBrandUseCase,
        _deleteBrandUseCase = deleteBrandUseCase,
        super(const BrandListInitial());

  /// Loads all brands
  Future<void> loadBrands() async {
    emit(const BrandListLoading());

    final result = await _getBrandsUseCase();

    result.fold(
      onSuccess: (brands) {
        if (brands.isEmpty) {
          emit(const BrandListEmpty());
        } else {
          emit(BrandListLoaded(
            brands: brands,
            filteredBrands: brands,
          ));
        }
      },
      onError: (failure) {
        emit(BrandListError(failure));
      },
    );
  }

  /// Searches brands
  void searchBrands(String query) {
    final currentState = state;
    if (currentState is! BrandListLoaded) return;

    final queryLower = query.toLowerCase();
    final filteredBrands = currentState.brands.where((brand) {
      return brand.name.toLowerCase().contains(queryLower) ||
          (brand.description?.toLowerCase().contains(queryLower) ?? false);
    }).toList();

    emit(currentState.copyWith(
      filteredBrands: filteredBrands,
      searchQuery: query,
    ));
  }

  /// Creates a new brand
  Future<BrandOperationState> createBrand({
    required String name,
    String? description,
    bool? useForRepair,
  }) async {
    final result = await _createBrandUseCase(CreateBrandParams(
      name: name,
      description: description,
      useForRepair: useForRepair,
    ));

    return result.fold(
      onSuccess: (_) {
        loadBrands(); // Refresh the list
        return const BrandOperationSuccess('Brand created successfully');
      },
      onError: (failure) => BrandOperationError(failure),
    );
  }

  /// Deletes a brand
  Future<BrandOperationState> deleteBrand(int id) async {
    final result = await _deleteBrandUseCase(id);

    return result.fold(
      onSuccess: (_) {
        loadBrands(); // Refresh the list
        return const BrandOperationSuccess('Brand deleted successfully');
      },
      onError: (failure) => BrandOperationError(failure),
    );
  }

  /// Refreshes the brand list
  Future<void> refresh() => loadBrands();
}

