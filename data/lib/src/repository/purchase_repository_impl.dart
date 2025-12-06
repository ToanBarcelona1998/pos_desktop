import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/remote/purchase_remote_data_source.dart';
import '../model/purchase_model.dart';

/// Implementation of [PurchaseRepository]
class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource _remoteDataSource;

  const PurchaseRepositoryImpl({
    required PurchaseRemoteDataSource remoteDataSource,
  })  : _remoteDataSource = remoteDataSource;

  @override
  Future<Result<List<PurchaseEntity>>> getPurchases({
    int? userId,
    int? businessId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (userId != null) query['user_id'] = userId;
      if (businessId != null) query['business_id'] = businessId;

      final purchases = await _remoteDataSource.getPurchases(query: query);
      final entities = purchases.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      Logger.logE('Error getting purchases', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<PurchaseEntity>> getPurchaseById(int id) async {
    try {
      final purchase = await _remoteDataSource.getPurchaseById(id);
      return Success(_mapToEntity(purchase));
    } catch (e) {
      Logger.logE('Error getting purchase by id', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<PurchaseEntity>> createPurchase(Map<String, dynamic> data) async {
    try {
      final purchase = await _remoteDataSource.createPurchase(data);
      return Success(_mapToEntity(purchase));
    } catch (e) {
      Logger.logE('Error creating purchase', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<PurchaseEntity>> updatePurchase(int id, Map<String, dynamic> data) async {
    try {
      final purchase = await _remoteDataSource.updatePurchase(id, data);
      return Success(_mapToEntity(purchase));
    } catch (e) {
      Logger.logE('Error updating purchase', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deletePurchase(int id) async {
    try {
      await _remoteDataSource.deletePurchase(id);
      return const Success(null);
    } catch (e) {
      Logger.logE('Error deleting purchase', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  PurchaseEntity _mapToEntity(PurchaseModel model) {
    return PurchaseEntity(
      id: model.id,
      document: null,
      transactionDate: model.transactionDate,
      refNo: model.refNo,
      name: '',
      status: model.status,
      paymentStatus: model.paymentStatus,
      finalTotal: model.finalTotal.toString(),
      locationName: '',
      payTermNumber: 0,
      payTermType: '',
      returnExists: 0,
      amountReturn: '0',
      addedBy: '',
    );
  }
}
