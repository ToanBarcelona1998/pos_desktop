import '../core/result.dart';
import '../entity/contact_entity.dart';

/// Abstract repository for contact operations.
/// This interface should be implemented in the data layer.
abstract class ContactRepository {
  /// Gets all contacts.
  /// [type] can be 'customer', 'supplier', etc.
  Future<Result<List<ContactEntity>>> getContacts({String? type});

  /// Gets a contact by ID.
  Future<Result<ContactEntity>> getContactById(int id);

  /// Creates a new contact.
  Future<Result<ContactEntity>> createContact(ContactEntity contact);

  /// Updates an existing contact.
  Future<Result<ContactEntity>> updateContact(ContactEntity contact);

  /// Deletes a contact.
  Future<Result<void>> deleteContact(int id);

  /// Searches contacts by name or mobile.
  Future<Result<List<ContactEntity>>> searchContacts(String query);

  /// Syncs contacts from remote to local storage.
  Future<Result<void>> syncContacts();

  /// Gets contacts from local cache.
  Future<Result<List<ContactEntity>>> getCachedContacts();

  /// Clears contact cache.
  Future<Result<void>> clearCache();
}












