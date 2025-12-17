import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/contact_entity.dart';
import '../../repository/contact_repository.dart';

/// Use case for getting contacts
class GetContactByIdUseCase implements UseCase<ContactEntity,int> {
  final ContactRepository _repository;

  const GetContactByIdUseCase(this._repository);

  @override
  Future<Result<ContactEntity>> call(int param) async {
    return await _repository.getContactById(param);
  }
}