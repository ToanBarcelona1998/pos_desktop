import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/report_remote_data_source.dart';
import '../model/report_model.dart';

/// Implementation of [ReportRepository]
class ReportRepositoryImpl implements ReportRepository {
  final ReportRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const ReportRepositoryImpl({
    required ReportRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<ProfitLossReportEntity>> getProfitLossReport({
    DateTime? startDate,
    DateTime? endDate,
    int? locationId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final query = <String, dynamic>{};
      if (startDate != null) query['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) query['end_date'] = endDate.toIso8601String().split('T')[0];
      if (locationId != null) query['location_id'] = locationId;

      final report = await _remoteDataSource.getProfitLossReport(query: query);
      return Success(_mapProfitLossToEntity(report));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ProductStockReportEntity>>> getProductStockReport({
    int? locationId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final query = <String, dynamic>{};
      if (locationId != null) query['location_id'] = locationId;

      final reports = await _remoteDataSource.getProductStockReport(query: query);
      final entities = reports.map(_mapProductStockToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  ProfitLossReportEntity _mapProfitLossToEntity(ProfitLossReportModel model) {
    return ProfitLossReportEntity(
      openingStock: model.openingStock,
      closingStock: model.closingStock,
      totalPurchase: model.totalPurchase,
      totalTransferShippingCharges: model.totalTransferShippingCharges,
      totalSell: model.totalSell,
      totalSellDiscount: model.totalSellDiscount,
      totalRecoveredDiscount: model.totalRecoveredDiscount,
      totalRewardAmount: model.totalRewardAmount,
      totalSellRoundOff: model.totalSellRoundOff,
      totalSellReturn: model.totalSellReturn,
      totalExpense: model.totalExpense,
      totalAdjustment: model.totalAdjustment,
      totalPurchaseShippingCharge: model.totalPurchaseShippingCharge,
      totalSellShippingCharge: model.totalSellShippingCharge,
      totalPurchaseReturn: model.totalPurchaseReturn,
      grossProfit: model.grossProfit,
      netProfit: model.netProfit,
    );
  }

  ProductStockReportEntity _mapProductStockToEntity(ProductStockReportModel model) {
    return ProductStockReportEntity(
      productId: model.productId,
      productName: model.productName,
      sku: model.sku,
      totalSold: model.totalSold,
      totalTransferred: model.totalTransferred,
      totalAdjusted: model.totalAdjusted,
      currentStock: model.currentStock,
      unitPrice: model.unitPrice,
      stockValue: model.stockValue,
    );
  }
}












