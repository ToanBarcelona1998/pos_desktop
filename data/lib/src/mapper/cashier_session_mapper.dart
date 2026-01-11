import 'package:domain/domain.dart';

import '../model/cashier_session_model.dart';
import 'base_mapper.dart';

/// Mapper for CashierSession
class CashierSessionMapper extends Mapper<CashierSessionModel, CashierSessionEntity> {
  const CashierSessionMapper();

  @override
  CashierSessionEntity toEntity(CashierSessionModel model) {
    return CashierSessionEntity(
      id: model.id,
      userId: model.userId,
      locationId: model.locationId,
      openingAmount: model.openingAmount,
      closingAmount: model.closingAmount,
      closingAmountOnStaff: model.closingAmountOnStaff,
      totalCardSlips: model.totalCardSlips,
      totalCheques: model.totalCheques,
      closingNote: model.closingNote,
      denominations: model.denominations,
      startTime: model.startTime,
      endTime: model.endTime,
      status: model.status,
      isSynced: model.isSynced,
    );
  }

  @override
  CashierSessionModel toModel(CashierSessionEntity entity) {
    return CashierSessionModel(
      id: entity.id,
      userId: entity.userId,
      locationId: entity.locationId,
      openingAmount: entity.openingAmount,
      closingAmount: entity.closingAmount,
      closingAmountOnStaff: entity.closingAmountOnStaff,
      totalCardSlips: entity.totalCardSlips,
      totalCheques: entity.totalCheques,
      closingNote: entity.closingNote,
      denominations: entity.denominations,
      startTime: entity.startTime,
      endTime: entity.endTime,
      status: entity.status,
      isSynced: entity.isSynced,
    );
  }
}
