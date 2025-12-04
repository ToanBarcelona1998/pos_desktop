import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/purchase_entity.dart';
import '../../repository/purchase_repository.dart';

/// Parameters for get purchases use case
class GetPurchasesParams {
  final int? userId;
  final int? businessId;

  const GetPurchasesParams({
    this.userId,
    this.businessId,
  });
}

/// Use case for getting purchases
class GetPurchasesUseCase implements UseCase<List<PurchaseEntity>, GetPurchasesParams> {
  final PurchaseRepository _repository;

  const GetPurchasesUseCase(this._repository);

  @override
  Future<Result<List<PurchaseEntity>>> call(GetPurchasesParams params) async {
    return await _repository.getPurchases(
      userId: params.userId,
      businessId: params.businessId,
    );
  }
}









