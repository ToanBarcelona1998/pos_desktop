import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/remote/contact_remote_data_source.dart';
import '../mapper/contact_mapper.dart';

/// Implementation of [ContactRepository]
class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final ContactMapper _mapper;

  const ContactRepositoryImpl({
    required ContactRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    ContactMapper mapper = const ContactMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _mapper = mapper;

  @override
  Future<Result<List<ContactEntity>>> getContacts({String? type}) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final contacts = await _remoteDataSource.getContacts(type: type);
      final entities = _mapper.toEntityList(contacts);
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<ContactEntity>> getContactById(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final contact = await _remoteDataSource.getContactById(id);
      return Success(_mapper.toEntity(contact));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<ContactEntity>> createContact(ContactEntity contact) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final model = _mapper.toModel(contact);
      final createdContact = await _remoteDataSource.createContact(model.toJson());
      return Success(_mapper.toEntity(createdContact));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<ContactEntity>> updateContact(ContactEntity contact) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final model = _mapper.toModel(contact);
      final updatedContact = await _remoteDataSource.updateContact(
        contact.id!,
        model.toJson(),
      );
      return Success(_mapper.toEntity(updatedContact));
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteContact(int id) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      await _remoteDataSource.deleteContact(id);
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ContactEntity>>> searchContacts(String query) async {
    final result = await getContacts();
    return result.fold(
      onSuccess: (contacts) {
        final filtered = contacts.where((c) {
          final queryLower = query.toLowerCase();
          return c.name.toLowerCase().contains(queryLower) ||
              (c.mobile?.toLowerCase().contains(queryLower) ?? false);
        }).toList();
        return Success(filtered);
      },
      onError: (failure) => Error(failure),
    );
  }

  @override
  Future<Result<void>> syncContacts() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      // Sync contacts from remote - implementation depends on local storage strategy
      await _remoteDataSource.getContacts();
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ContactEntity>>> getCachedContacts() async {
    // Return empty list if no cache is available
    // Implementation depends on local data source
    return const Success([]);
  }

  @override
  Future<Result<void>> clearCache() async {
    // Clear cache implementation depends on local data source
    return const Success(null);
  }
}
