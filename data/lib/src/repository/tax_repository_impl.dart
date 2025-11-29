import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/tax_remote_data_source.dart';
import '../model/tax_model.dart';

/// Implementation of [TaxRepository]
class TaxRepositoryImpl implements TaxRepository {
  final TaxRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  const TaxRepositoryImpl({
    required TaxRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<Result<List<TaxEntity>>> getTaxes() async {
    if (!await _networkInfo.isConnected) {
      return getLocalTaxes();
    }

    try {
      final taxes = await _remoteDataSource.getTaxes();
      final entities = taxes.map(_mapToEntity).toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<TaxEntity>> getTaxById(int id) async {
    final result = await getTaxes();
    return result.fold(
      onSuccess: (taxes) {
        final tax = taxes.where((t) => t.id == id).firstOrNull;
        if (tax == null) {
          return const Error(NotFoundFailure(message: 'Tax not found'));
        }
        return Success(tax);
      },
      onError: (failure) => Error(failure),
    );
  }

  @override
  Future<Result<void>> syncTaxes() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final taxes = await _remoteDataSource.getTaxes();
      final taxesJson = taxes.map((t) => t.toJson()).toList();
      await _localDataSource.insert('tax', jsonEncode(taxesJson));
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<TaxEntity>>> getLocalTaxes() async {
    try {
      final data = await _localDataSource.get('tax');
      if (data == null) {
        return const Success([]);
      }

      final List<dynamic> taxList = data is String ? jsonDecode(data) : data;
      final entities = taxList
          .map((json) => TaxModel.fromJson(json as Map<String, dynamic>))
          .map(_mapToEntity)
          .toList();
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  TaxEntity _mapToEntity(TaxModel model) {
    return TaxEntity(
      id: model.id,
      businessId: model.businessId,
      name: model.name,
      amount: model.amount,
      isTaxGroup: model.isTaxGroup == 1,
      forTaxGroup: model.forTaxGroup == 1,
      createdAt: model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      updatedAt: model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null,
      deletedAt: model.deletedAt != null ? DateTime.tryParse(model.deletedAt!) : null,
    );
  }
}

