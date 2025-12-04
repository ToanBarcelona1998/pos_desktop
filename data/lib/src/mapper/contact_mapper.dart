import 'package:domain/domain.dart';

import '../model/contact_model.dart';
import 'base_mapper.dart';

/// Mapper for Contact
class ContactMapper extends Mapper<ContactModel, ContactEntity> {
  const ContactMapper();

  @override
  ContactEntity toEntity(ContactModel model) {
    return ContactEntity(
      id: model.id,
      name: model.supplierBusinessName ?? model.name ?? '',
      mobile: model.mobile,
      prefix: model.prefix,
      firstName: model.firstName,
      middleName: model.middleName,
      lastName: model.lastName,
      addressLine1: model.addressLine1,
      addressLine2: model.addressLine2,
      city: model.city,
      state: model.state,
      country: model.country,
      zipCode: model.zipCode,
      type: model.type ?? 'customer',
    );
  }

  @override
  ContactModel toModel(ContactEntity entity) {
    return ContactModel(
      id: entity.id,
      name: entity.name,
      mobile: entity.mobile,
      prefix: entity.prefix,
      firstName: entity.firstName,
      middleName: entity.middleName,
      lastName: entity.lastName,
      addressLine1: entity.addressLine1,
      addressLine2: entity.addressLine2,
      city: entity.city,
      state: entity.state,
      country: entity.country,
      zipCode: entity.zipCode,
      type: entity.type,
    );
  }
}











