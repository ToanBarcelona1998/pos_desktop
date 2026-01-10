import 'package:domain/domain.dart';

import '../model/exchange_rate_model.dart';
import 'base_mapper.dart';

class ExchangeRateMapper extends Mapper<ExchangeRateModel, ExchangeRateEntity> {
  const ExchangeRateMapper();

  @override
  ExchangeRateEntity toEntity(ExchangeRateModel model) {
    return ExchangeRateEntity(
      baseCurrency: model.baseCurrency,
      targetCurrency: model.targetCurrency,
      conversionRate: model.conversionRate,
      lastUpdateDate: model.lastUpdateDate,
      nextUpdateDate: model.nextUpdateDate,
      source: model.source,
      isFromCache: model.isFromCache,
    );
  }

  @override
  ExchangeRateModel toModel(ExchangeRateEntity entity) {
    return ExchangeRateModel(
      baseCurrency: entity.baseCurrency,
      targetCurrency: entity.targetCurrency,
      conversionRate: entity.conversionRate,
      lastUpdateDate: entity.lastUpdateDate,
      nextUpdateDate: entity.nextUpdateDate,
      source: entity.source,
      isFromCache: entity.isFromCache,
    );
  }
}
