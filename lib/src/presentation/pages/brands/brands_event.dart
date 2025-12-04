import 'package:domain/domain.dart';

import '../../base/base_event.dart';

/// Brands page events
sealed class BrandsEvent extends BaseEvent {
  const BrandsEvent();
}

/// Load brands
class BrandsLoad extends BrandsEvent {
  const BrandsLoad();
}

/// Refresh brands
class BrandsRefresh extends BrandsEvent {
  const BrandsRefresh();
}

/// Search brands
class BrandsSearch extends BrandsEvent {
  final String query;
  const BrandsSearch(this.query);
}

/// Add brand
class BrandsAdd extends BrandsEvent {
  final String name;
  final String? description;
  const BrandsAdd({required this.name, this.description});
}

/// Update brand
class BrandsUpdate extends BrandsEvent {
  final BrandEntity brand;
  const BrandsUpdate(this.brand);
}

/// Delete brand
class BrandsDelete extends BrandsEvent {
  final int id;
  const BrandsDelete(this.id);
}








