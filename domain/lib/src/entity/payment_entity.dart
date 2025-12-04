import '../core/entity.dart';

/// Payment method entity
class PaymentMethodEntity extends Entity {
  final String name;
  final String? label;
  final bool isActive;

  const PaymentMethodEntity({
    required this.name,
    this.label,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [name, label, isActive];
}

/// Payment account entity
class PaymentAccountEntity extends Entity {
  final int id;
  final int businessId;
  final String name;
  final String accountNumber;
  final String? accountType;
  final String? note;
  final bool isActive;
  final bool isClosed;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentAccountEntity({
    required this.id,
    required this.businessId,
    required this.name,
    required this.accountNumber,
    this.accountType,
    this.note,
    this.isActive = true,
    this.isClosed = false,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        name,
        accountNumber,
        accountType,
        note,
        isActive,
        isClosed,
        createdAt,
        updatedAt,
      ];
}

/// Contact payment entity
class ContactPaymentEntity extends Entity {
  final int? id;
  final int contactId;
  final double amount;
  final String method;
  final String? note;
  final int? accountId;
  final DateTime? paidOn;
  final DateTime? createdAt;

  const ContactPaymentEntity({
    this.id,
    required this.contactId,
    required this.amount,
    required this.method,
    this.note,
    this.accountId,
    this.paidOn,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        contactId,
        amount,
        method,
        note,
        accountId,
        paidOn,
        createdAt,
      ];
}









