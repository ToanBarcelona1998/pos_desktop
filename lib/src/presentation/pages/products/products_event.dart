import '../../base/base_event.dart';

/// Products page events
sealed class ProductsEvent extends BaseEvent {
  const ProductsEvent();
}

/// Load products
class ProductsLoad extends ProductsEvent {
  final int locationId;
  const ProductsLoad({required this.locationId});
}

/// Load more products (pagination)
class ProductsLoadMore extends ProductsEvent {
  const ProductsLoadMore();
}

/// Refresh products
class ProductsRefresh extends ProductsEvent {
  const ProductsRefresh();
}

/// Search products
class ProductsSearch extends ProductsEvent {
  final String query;
  const ProductsSearch(this.query);
}

/// Filter by category
class ProductsFilterByCategory extends ProductsEvent {
  final int? categoryId;
  const ProductsFilterByCategory(this.categoryId);
}

/// Filter by brand
class ProductsFilterByBrand extends ProductsEvent {
  final int? brandId;
  const ProductsFilterByBrand(this.brandId);
}

/// Change location
class ProductsChangeLocation extends ProductsEvent {
  final int locationId;
  const ProductsChangeLocation(this.locationId);
}

/// Sync products from remote
class ProductsSync extends ProductsEvent {
  const ProductsSync();
}




