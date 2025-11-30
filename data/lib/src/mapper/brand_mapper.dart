import 'package:domain/domain.dart';

import '../model/brand_model.dart';
import 'base_mapper.dart';

/// Mapper for Brand
class BrandMapper extends ReadOnlyMapper<BrandModel, BrandEntity> {
  const BrandMapper();

  @override
  BrandEntity toEntity(BrandModel model) {
    return BrandEntity(
      id: model.id,
      businessId: model.businessId,
      name: model.name,
      description: model.description,
      createdBy: model.createdBy,
      useForRepair: model.useForRepair == 1,
      deletedAt:
          model.deletedAt != null ? DateTime.tryParse(model.deletedAt!) : null,
      createdAt: DateTime.parse(model.createdAt),
      updatedAt: DateTime.parse(model.updatedAt),
    );
  }
}





