import 'package:domain/domain.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_config/di.dart';
import 'brands_event.dart';
import 'brands_state.dart';

/// Brands page bloc
class BrandsBloc extends Bloc<BrandsEvent, BrandsState> {
  final BrandRepository _brandRepository;
  final GetBrandsUseCase _getBrandsUseCase;
  final CreateBrandUseCase _createBrandUseCase;
  final DeleteBrandUseCase _deleteBrandUseCase;

  BrandsBloc({
    BrandRepository? brandRepository,
    GetBrandsUseCase? getBrandsUseCase,
    CreateBrandUseCase? createBrandUseCase,
    DeleteBrandUseCase? deleteBrandUseCase,
  })  : _brandRepository = brandRepository ?? sl.get<BrandRepository>(),
        _getBrandsUseCase = getBrandsUseCase ?? sl.get<GetBrandsUseCase>(),
        _createBrandUseCase =
            createBrandUseCase ?? sl.get<CreateBrandUseCase>(),
        _deleteBrandUseCase =
            deleteBrandUseCase ?? sl.get<DeleteBrandUseCase>(),
        super(BrandsState.initial()) {
    on<BrandsLoad>(_onLoad);
    on<BrandsRefresh>(_onRefresh);
    on<BrandsSearch>(_onSearch);
    on<BrandsAdd>(_onAdd);
    on<BrandsUpdate>(_onUpdate);
    on<BrandsDelete>(_onDelete);
  }

  Future<void> _onLoad(
    BrandsLoad event,
    Emitter<BrandsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearMessages: true));

    final result = await _getBrandsUseCase.call();

    result.fold(
      onSuccess: (brands) {
        emit(state.copyWith(
          isLoading: false,
          brands: brands,
          filteredBrands: brands,
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

  Future<void> _onRefresh(
    BrandsRefresh event,
    Emitter<BrandsState> emit,
  ) async {
    add(const BrandsLoad());
  }

  void _onSearch(
    BrandsSearch event,
    Emitter<BrandsState> emit,
  ) {
    final query = event.query.toLowerCase();
    final filtered = state.brands.where((brand) {
      return brand.name.toLowerCase().contains(query);
    }).toList();

    emit(state.copyWith(
      searchQuery: event.query,
      filteredBrands: filtered,
    ));
  }

  Future<void> _onAdd(
    BrandsAdd event,
    Emitter<BrandsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    final brand = CreateBrandParams(
      name: event.name,
      description: event.description,
    );

    final result = await _createBrandUseCase.call(brand);

    result.fold(
      onSuccess: (createdBrand) {
        final updatedBrands = [...state.brands, createdBrand];
        emit(state.copyWith(
          isSubmitting: false,
          brands: updatedBrands,
          filteredBrands: _applySearch(updatedBrands, state.searchQuery),
          successMessage: 'Brand added successfully',
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: failure,
        ));
      },
    );
  }

  Future<void> _onUpdate(
    BrandsUpdate event,
    Emitter<BrandsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    final result = await _brandRepository.updateBrand(
      id: event.brand.id,
      name: event.brand.name,
      description: event.brand.description,
      useForRepair: event.brand.useForRepair,
    );

    result.fold(
      onSuccess: (updatedBrand) {
        final updatedBrands = state.brands.map((b) {
          return b.id == updatedBrand.id ? updatedBrand : b;
        }).toList();

        emit(state.copyWith(
          isSubmitting: false,
          brands: updatedBrands,
          filteredBrands: _applySearch(updatedBrands, state.searchQuery),
          successMessage: 'Brand updated successfully',
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: failure,
        ));
      },
    );
  }

  Future<void> _onDelete(
    BrandsDelete event,
    Emitter<BrandsState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));

    final result = await _deleteBrandUseCase.call(event.id);

    result.fold(
      onSuccess: (_) {
        final updatedBrands =
            state.brands.where((b) => b.id != event.id).toList();

        emit(state.copyWith(
          isSubmitting: false,
          brands: updatedBrands,
          filteredBrands: _applySearch(updatedBrands, state.searchQuery),
          successMessage: 'Brand deleted successfully',
        ));
      },
      onError: (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          failure: failure,
        ));
      },
    );
  }

  List<BrandEntity> _applySearch(List<BrandEntity> brands, String query) {
    if (query.isEmpty) return brands;
    return brands
        .where((b) => b.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}









