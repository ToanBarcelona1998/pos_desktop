import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/layout_bill_entity.dart';
import '../../repository/layout_bill_repository.dart';

/// Parameters for getting layout bill use case
class GetLayoutBillParams {
  final int locationId;

  const GetLayoutBillParams({required this.locationId});
}

/// Use case for getting layout bill
class GetLayoutBillUseCase
    implements UseCase<LayoutBillEntity, GetLayoutBillParams> {
  final LayoutBillRepository _repository;

  const GetLayoutBillUseCase(this._repository);

  @override
  Future<Result<LayoutBillEntity>> call(GetLayoutBillParams params) async {
    return await _repository.getLayoutBill(params.locationId);
  }
}

