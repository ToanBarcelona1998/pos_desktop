import 'package:domain/domain.dart';

import '../core/exception_handler.dart';
import '../core/network_info.dart';
import '../data_source/local/contact_local_data_source.dart';
import '../data_source/remote/contact_remote_data_source.dart';
import '../mapper/contact_mapper.dart';

/// Implementation of [ContactRepository]
/// Prioritizes local data for offline-first approach
class ContactRepositoryImpl implements ContactRepository {
  final ContactRemoteDataSource _remoteDataSource;
  final ContactLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final ContactMapper _mapper;

  const ContactRepositoryImpl({
    required ContactRemoteDataSource remoteDataSource,
    required ContactLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
    ContactMapper mapper = const ContactMapper(),
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo,
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
          // If online, sync in background for next time
          if (await _networkInfo.isConnected) {
            _syncContactsInBackground(type: type);
          }
          return Success(filteredContacts);
        }
        
        // No local data - try remote if online
        if (await _networkInfo.isConnected) {
          try {
            final contacts = await _remoteDataSource.getContacts(type: type, perPage: 750);
            final entities = _mapper.toEntityList(contacts);
            
            // Save to local
            await syncContacts();
            
            return Success(entities);
          } catch (e) {
            return Error(ExceptionHandler.handleException(e));
          }
        }
        
        // Offline and no local data
        return const Success([]);
      },
      onError: (failure) async {
        // Local fetch failed - try remote if online
        if (await _networkInfo.isConnected) {
          try {
            final contacts = await _remoteDataSource.getContacts(type: type, perPage: 750);
            final entities = _mapper.toEntityList(contacts);
            
            // Save to local
            await syncContacts();
            
            return Success(entities);
          } catch (e) {
            return Error(ExceptionHandler.handleException(e));
          }
        }
        
        return Error(failure);
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
      print('Error getting local contact: $e');
    }

    // If online, try remote
    if (await _networkInfo.isConnected) {
      try {
        final contact = await _remoteDataSource.getContactById(id);
        return Success(_mapper.toEntity(contact));
      } catch (e) {
        return Error(ExceptionHandler.handleException(e));
      }
    }

    return const Error(NotFoundFailure(message: 'Contact not found'));
  }

  @override
  Future<Result<ContactEntity>> createContact(ContactEntity contact) async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      final model = _mapper.toModel(contact);
      final createdContact = await _remoteDataSource.createContact(model.toJson());
      final entity = _mapper.toEntity(createdContact);
      
      // Save to local
      await _localDataSource.saveContacts([createdContact]);
      
      return Success(entity);
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
      final entity = _mapper.toEntity(updatedContact);
      
      // Update local
      await _localDataSource.saveContacts([updatedContact]);
      
      return Success(entity);
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
      
      // Remove from local (optional - might want to keep for history)
      // await _localDataSource.deleteContact(id);
      
      return const Success(null);
    } catch (e) {
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
        // If online, try remote search
        if (await _networkInfo.isConnected) {
          return getContacts();
        }
        return Error(failure);
      },
    );
  }

  /// Sync contacts in background without blocking
  void _syncContactsInBackground({String? type}) {
    syncContacts().catchError((e) {
      print('Background contact sync error: $e');
    });
  }

  @override
  Future<Result<void>> syncContacts() async {
    if (!await _networkInfo.isConnected) {
      return const Error(NetworkFailure());
    }

    try {
      // Fetch all contacts (customers)
      final contacts = await _remoteDataSource.getContacts(type: 'customer', perPage: 750);
      
      // Save to local
      await _localDataSource.saveContacts(contacts);
      
      return const Success(null);
    } catch (e) {
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
