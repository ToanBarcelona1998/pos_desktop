import 'package:domain/domain.dart';

/// States for Brand List feature
sealed class BrandListState {
  const BrandListState();
}

/// Initial state
class BrandListInitial extends BrandListState {
  const BrandListInitial();
}

/// Loading state
class BrandListLoading extends BrandListState {
  const BrandListLoading();
}

/// Success state with brands
class BrandListLoaded extends BrandListState {
  final List<BrandEntity> brands;
  final List<BrandEntity> filteredBrands;
  final String searchQuery;

  const BrandListLoaded({
    required this.brands,
    required this.filteredBrands,
    this.searchQuery = '',
  });

  BrandListLoaded copyWith({
    List<BrandEntity>? brands,
    List<BrandEntity>? filteredBrands,
    String? searchQuery,
  }) {
    return BrandListLoaded(
      brands: brands ?? this.brands,
      filteredBrands: filteredBrands ?? this.filteredBrands,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Error state
class BrandListError extends BrandListState {
  final Failure failure;

  const BrandListError(this.failure);

  String get message => failure.message;
}

/// Empty state
class BrandListEmpty extends BrandListState {
  const BrandListEmpty();
}

/// Brand operation states (for create, update, delete)
sealed class BrandOperationState {
  const BrandOperationState();
}

class BrandOperationIdle extends BrandOperationState {
  const BrandOperationIdle();
}

class BrandOperationLoading extends BrandOperationState {
  const BrandOperationLoading();
}

class BrandOperationSuccess extends BrandOperationState {
  final String message;
  const BrandOperationSuccess(this.message);
}

class BrandOperationError extends BrandOperationState {
  final Failure failure;
  const BrandOperationError(this.failure);
}

