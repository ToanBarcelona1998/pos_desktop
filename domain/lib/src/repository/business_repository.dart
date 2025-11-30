import '../core/result.dart';
import '../entity/business_entity.dart';

/// Repository interface for business operations
abstract class BusinessRepository {
  /// Get business details
  Future<Result<BusinessEntity>> getBusinessDetails();

  /// Sync business details from remote to local
  Future<Result<void>> syncBusinessDetails();

  /// Get business details from local storage
  Future<Result<BusinessEntity?>> getLocalBusinessDetails();
}




