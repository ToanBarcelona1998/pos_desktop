import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/sell_remote_data_source.dart';
import '../model/sell_model.dart';

/// Implementation of [SellRepository]
class SellRepositoryImpl implements SellRepository {
  final SellRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  const SellRepositoryImpl({
    required SellRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<SellEntity>> createSell(SellEntity sell) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = _entityToMap(sell);
      final model = await _remoteDataSource.createSell(data);
      return Success(_mapToEntity(model));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<SellEntity>> updateSell(SellEntity sell) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final data = _entityToMap(sell);
      final model = await _remoteDataSource.updateSell(sell.id, data);
      return Success(_mapToEntity(model));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteSell(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.deleteSell(id);
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<SellEntity>> getSellById(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final sells = await _remoteDataSource.getSpecifiedSells([id]);
      if (sells.isEmpty) {
        return const Error(NotFoundFailure(message: 'Sell not found'));
      }
      return Success(_mapToEntity(sells.first));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<SellEntity>>> getSellsByIds(List<int> ids) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final sells = await _remoteDataSource.getSpecifiedSells(ids);
      return Success(sells.map(_mapToEntity).toList());
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<SellEntity>>> getLocalSells() async {
    // Implementation for getting local sells
    return const Success([]);
  }

  @override
  Future<Result<void>> syncSells() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      // Sync implementation
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<SellEntity>> saveSellLocally(SellEntity sell) async {
    try {
      // Save locally implementation
      return Success(sell);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<SellEntity>>> getDraftSells() async {
    return const Success([]);
  }

  @override
  Future<Result<List<SellEntity>>> getQuotations() async {
    return const Success([]);
  }

  @override
  Future<Result<List<SellEntity>>> getSuspendedSells() async {
    return const Success([]);
  }

  SellEntity _mapToEntity(SellModel model) {
    return SellEntity(
      id: model.id,
      transactionDate: model.transactionDate,
      invoiceNo: model.invoiceNo,
      contactId: model.contactId,
      locationId: model.locationId,
      status: model.status,
      discountAmount: model.discount,
      isQuotation: model.isQuotation == 1,
      isSuspend: model.isSuspend == 1,
      invoiceAmount: model.finalTotal,
      changeReturn: model.changeReturn,
      invoiceUrl: model.invoiceUrl,
    );
  }

  Map<String, dynamic> _entityToMap(SellEntity entity) {
    return {
      if (entity.transactionDate != null) 'transaction_date': entity.transactionDate,
      if (entity.contactId != null) 'contact_id': entity.contactId,
      if (entity.locationId != null) 'location_id': entity.locationId,
      if (entity.status != null) 'status': entity.status,
      if (entity.discountAmount != null) 'discount_amount': entity.discountAmount,
      if (entity.discountType != null) 'discount_type': entity.discountType,
      'is_quotation': entity.isQuotation ? 1 : 0,
      'is_suspend': entity.isSuspend ? 1 : 0,
      if (entity.saleNote != null) 'sale_note': entity.saleNote,
      if (entity.staffNote != null) 'staff_note': entity.staffNote,
    };
  }
}
