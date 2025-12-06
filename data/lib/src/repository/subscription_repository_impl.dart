import 'dart:convert';

import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/local/system_local_data_source.dart';
import '../data_source/remote/subscription_remote_data_source.dart';
import '../model/subscription_model.dart';

/// Implementation of [SubscriptionRepository]
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final SubscriptionRemoteDataSource _remoteDataSource;
  final SystemLocalDataSource _localDataSource;

  const SubscriptionRepositoryImpl({
    required SubscriptionRemoteDataSource remoteDataSource,
    required SystemLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<Result<SubscriptionEntity?>> getActiveSubscription() async {
    try {
      final subscription = await _remoteDataSource.getActiveSubscription();
      if (subscription == null) {
        return const Success(null);
      }
      return Success(_mapToEntity(subscription));
    } catch (e) {
      Logger.logE('Failed to get active subscription from server, trying local', e);
      return getLocalActiveSubscription();
    }
  }

  @override
  Future<Result<void>> syncActiveSubscription() async {
    try {
      final subscription = await _remoteDataSource.getActiveSubscription();
      if (subscription != null) {
        await _localDataSource.insert(
          'active-subscription',
          jsonEncode([subscription.toJson()]),
        );
      } else {
        await _localDataSource.insert('active-subscription', jsonEncode([]));
      }
      return const Success(null);
    } catch (e) {
      Logger.logE('Error syncing active subscription', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<SubscriptionEntity?>> getLocalActiveSubscription() async {
    try {
      final data = await _localDataSource.get('active-subscription');
      if (data == null) {
        return const Success(null);
      }

      final List<dynamic> subscriptionList = data is String ? jsonDecode(data) : data;
      if (subscriptionList.isEmpty) {
        return const Success(null);
      }

      final model = SubscriptionModel.fromJson(
        subscriptionList.first as Map<String, dynamic>,
      );
      return Success(_mapToEntity(model));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  SubscriptionEntity _mapToEntity(SubscriptionModel model) {
    return SubscriptionEntity(
      id: model.id,
      businessId: model.businessId,
      packageId: model.packageId,
      packageName: model.packageName,
      startDate: DateTime.parse(model.startDate),
      endDate: DateTime.parse(model.endDate),
      trialEndDate: model.trialEndDate != null ? DateTime.tryParse(model.trialEndDate!) : null,
      status: model.status,
      packagePrice: model.packagePrice,
      packageInterval: model.packageInterval,
      packageIntervalCount: model.packageIntervalCount,
      createdAt: model.createdAt != null ? DateTime.tryParse(model.createdAt!) : null,
      updatedAt: model.updatedAt != null ? DateTime.tryParse(model.updatedAt!) : null,
    );
  }
}












