import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/layout_bill_remote_data_source.dart';

/// Implementation of [LayoutBillRepository]
class LayoutBillRepositoryImpl implements LayoutBillRepository {
  final LayoutBillRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;

  const LayoutBillRepositoryImpl({
    required LayoutBillRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Result<LayoutBillEntity>> getLayoutBill(int locationId) async {
    try {
      // Try to get from local first for offline support
      final localResult = await _getLocalLayoutBill(locationId);
      if (localResult is Success) {
        return localResult;
      }

      // If local data not available, fetch from remote
      final data = await _remoteDataSource.getLayoutBill(locationId);
      final entity = _mapToEntity(data);
      return Success(entity);
    } catch (e) {
      Logger.logE('Failed to fetch layout bill', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  Future<Result<LayoutBillEntity>> _getLocalLayoutBill(int locationId) async {
    try {
      final data = await _localDataSource.getByKeyId('layout_bill', locationId);
      if (data == null) {
        return Error(NotFoundFailure(message: 'No cached layout bill data'));
      }

      final Map<String, dynamic> billData =
          data is String ? jsonDecode(data) : data as Map<String, dynamic>;
      final entity = _mapToEntity(billData);
      return Success(entity);
    } catch (e) {
      Logger.logE('Error getting local layout bill', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  LayoutBillEntity _mapToEntity(Map<String, dynamic> json) {
    final locationJson = json['location'] as Map<String, dynamic>;
    final businessJson = json['business'] as Map<String, dynamic>;

    return LayoutBillEntity(
      location: _mapLocationToEntity(locationJson),
      business: _mapBusinessToEntity(businessJson),
    );
  }

  LayoutBillLocationEntity _mapLocationToEntity(Map<String, dynamic> json) {
    return LayoutBillLocationEntity(
      id: json['id'] as int,
      name: json['name'] as String,
      landmark: json['landmark']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      zipCode: json['zip_code']?.toString(),
      mobile: json['mobile']?.toString(),
      alternateNumber: json['alternate_number']?.toString(),
      email: json['email']?.toString(),
      website: json['website']?.toString(),
    );
  }

  LayoutBillBusinessEntity _mapBusinessToEntity(Map<String, dynamic> json) {
    return LayoutBillBusinessEntity(
      name: json['name'] as String,
      logo: json['logo']?.toString(),
      cachedLogoPath: json['cached_logo_path']?.toString(),
      mobile: json['mobile']?.toString(),
      alternateNumber: json['alternate_number']?.toString(),
      email: json['email']?.toString(),
    );
  }
}
