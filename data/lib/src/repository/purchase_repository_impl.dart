import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/purchase_remote_data_source.dart';
import '../model/purchase_model.dart';

/// Implementation of [PurchaseRepository]
class PurchaseRepositoryImpl implements PurchaseRepository {
  final PurchaseRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const PurchaseRepositoryImpl({
    required PurchaseRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<PurchaseEntity>>> getPurchases({
    int? userId,
    int? businessId,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final query = <String, dynamic>{};
      if (userId != null) query['user_id'] = userId;
      if (businessId != null) query['business_id'] = businessId;

      final purchases = await _remoteDataSource.getPurchases(query: query);
      final entities = purchases.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<PurchaseEntity>> getPurchaseById(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final purchase = await _remoteDataSource.getPurchaseById(id);
      return Success(_mapToEntity(purchase));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<PurchaseEntity>> createPurchase(Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final purchase = await _remoteDataSource.createPurchase(data);
      return Success(_mapToEntity(purchase));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<PurchaseEntity>> updatePurchase(int id, Map<String, dynamic> data) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final purchase = await _remoteDataSource.updatePurchase(id, data);
      return Success(_mapToEntity(purchase));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deletePurchase(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.deletePurchase(id);
      return const Success(null);
    } catch (e) {
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
