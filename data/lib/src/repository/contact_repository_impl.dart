import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../data_source/local/contact_local_data_source.dart';
import '../data_source/remote/contact_remote_data_source.dart';
import '../mapper/contact_mapper.dart';

/// Implementation of [ContactRepository]
/// Prioritizes local data for offline-first approach
class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource _remoteDataSource;
  final ContactLocalDataSource _localDataSource;
  final ContactMapper _mapper;

  const ContactRepositoryImpl({
    required ContactRemoteDataSource remoteDataSource,
    required ContactLocalDataSource localDataSource,
    ContactMapper mapper = const ContactMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _mapper = mapper;

  @override
  Future<Result<List<ContactEntity>>> getContacts({String? type}) async {
    // Always try local first (offline-first)
    final localResult = await getCachedContacts();
    
    return localResult.fold(
      onSuccess: (localContacts) async {
        // Filter by type if needed
        var filteredContacts = localContacts;
        if (type != null) {
          filteredContacts = localContacts.where((c) => c.type == type).toList();
        }
        
        // If we have local data, return it immediately
        if (filteredContacts.isNotEmpty) {
          // Sync in background for next time
          _syncContactsInBackground(type: type);
          return Success(filteredContacts);
        }
        
        // No local data - try remote
        try {
          final contacts = await _remoteDataSource.getContacts(type: type, perPage: 750);
          final entities = _mapper.toEntityList(contacts);
          
          // Save to local
          await syncContacts();
          
          return Success(entities);
        } catch (e) {
          Logger.logE('Failed to fetch contacts from server', e);
          // Offline and no local data
          return const Success([]);
        }
      },
      onError: (failure) async {
        // Local fetch failed - try remote
        try {
          final contacts = await _remoteDataSource.getContacts(type: type, perPage: 750);
          final entities = _mapper.toEntityList(contacts);
          
          // Save to local
          await syncContacts();
          
          return Success(entities);
        } catch (e) {
          Logger.logE('Failed to fetch contacts from server after local error', e);
          return Error(failure);
        }
      },
    );
  }

  @override
  Future<Result<ContactEntity>> getContactById(int id) async {
    // Try local first
    try {
      final contact = await _localDataSource.getContactById(id);
      if (contact != null) {
        return Success(_mapper.toEntity(contact));
      }
    } catch (e) {
      Logger.logE('Error getting local contact', e);
    }

    // Try remote
    try {
      final contact = await _remoteDataSource.getContactById(id);
      return Success(_mapper.toEntity(contact));
    } catch (e) {
      Logger.logE('Failed to get contact from server', e);
      return const Error(NotFoundFailure(message: 'Contact not found'));
    }
  }

  @override
  Future<Result<ContactEntity>> createContact(ContactEntity contact) async {
    try {
      final model = _mapper.toModel(contact);
      final createdContact = await _remoteDataSource.createContact(model.toJson());
      final entity = _mapper.toEntity(createdContact);
      
      // Save to local
      await _localDataSource.saveContacts([createdContact]);
      
      return Success(entity);
    } catch (e) {
      Logger.logE('Error creating contact', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<ContactEntity>> updateContact(ContactEntity contact) async {
    try {
      final model = _mapper.toModel(contact);
      final updatedContact = await _remoteDataSource.updateContact(
        contact.id!,
        model.toJson(),
      );
      final entity = _mapper.toEntity(updatedContact);
      
      // Update local
      await _localDataSource.saveContacts([updatedContact]);
      
      return Success(entity);
    } catch (e) {
      Logger.logE('Error updating contact', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> deleteContact(int id) async {
    try {
      await _remoteDataSource.deleteContact(id);
      
      // Remove from local (optional - might want to keep for history)
      // await _localDataSource.deleteContact(id);
      
      return const Success(null);
    } catch (e) {
      Logger.logE('Error deleting contact', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ContactEntity>>> searchContacts(String query) async {
    // Always search local first
    final localResult = await getCachedContacts();
    
    return localResult.fold(
      onSuccess: (contacts) {
        final queryLower = query.toLowerCase();
        final filtered = contacts.where((c) {
          return c.name.toLowerCase().contains(queryLower) ||
              (c.mobile?.toLowerCase().contains(queryLower) ?? false);
        }).toList();
        return Success(filtered);
      },
      onError: (failure) async {
        // Try remote search
        try {
          return await getContacts();
        } catch (e) {
          Logger.logE('Failed to search contacts from server', e);
          return Error(failure);
        }
      },
    );
  }

  /// Sync contacts in background without blocking
  void _syncContactsInBackground({String? type}) {
    syncContacts().catchError((e) {
      Logger.logE('Background contact sync error', e);
    });
  }

  @override
  Future<Result<void>> syncContacts() async {
    try {
      // Fetch all contacts (customers)
      final contacts = await _remoteDataSource.getContacts(type: 'customer', perPage: 750);
      
      // Save to local
      await _localDataSource.saveContacts(contacts);
      
      return const Success(null);
    } catch (e) {
      Logger.logE('Error syncing contacts', e);
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<List<ContactEntity>>> getCachedContacts() async {
    try {
      final contacts = await _localDataSource.getContacts();
      final entities = _mapper.toEntityList(contacts);
      return Success(entities);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Result<void>> clearCache() async {
    try {
      await _localDataSource.clearCache();
      return const Success(null);
    } catch (e) {
      return Error(ExceptionHandler.handleException(e));
    }
  }
}
