import '../core/result.dart';
import '../entity/subscription_entity.dart';

/// Repository interface for subscription operations
abstract class SubscriptionRepository {
  /// Get active subscription
  Future<Result<SubscriptionEntity?>> getActiveSubscription();

  /// Sync active subscription from remote to local
  Future<Result<void>> syncActiveSubscription();

  /// Get active subscription from local storage
  Future<Result<SubscriptionEntity?>> getLocalActiveSubscription();
}

