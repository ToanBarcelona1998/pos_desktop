import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/payment_entity.dart';
import '../../repository/payment_repository.dart';

class GetPaymentAccountsByTypeParams {
  final String paymentMethod;

  const GetPaymentAccountsByTypeParams({
    required this.paymentMethod,
  });
}

class GetPaymentAccountsByTypeUseCase
    implements UseCase<List<PaymentAccountEntity>, GetPaymentAccountsByTypeParams> {
  final PaymentRepository _repository;

  const GetPaymentAccountsByTypeUseCase(this._repository);

  @override
  Future<Result<List<PaymentAccountEntity>>> call(
    GetPaymentAccountsByTypeParams params,
  ) async {
    return await _repository.getPaymentAccountsByType(params.paymentMethod);
  }
}

