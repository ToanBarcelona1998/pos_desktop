import '../../core/result.dart';
import '../../core/use_case.dart';
import '../../entity/contact_entity.dart';
import '../../repository/contact_repository.dart';

/// Use case for getting contacts
class GetContactsUseCase implements UseCaseNoParams<List<ContactEntity>> {
  final ContactRepository _repository;

  const GetContactsUseCase(this._repository);

  @override
  Future<Result<List<ContactEntity>>> call() async {
    return await _repository.getContacts();
  }
}

/// Use case for searching contacts
class SearchContactsUseCase implements UseCase<List<ContactEntity>, String> {
  final ContactRepository _repository;

  const SearchContactsUseCase(this._repository);

  @override
  Future<Result<List<ContactEntity>>> call(String query) async {
    return await _repository.searchContacts(query);
  }
}
