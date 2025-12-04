import '../core/entity.dart';

/// Expense category entity
class ExpenseCategoryEntity extends Entity {
  final int id;
  final String name;
  final int businessId;
  final String? code;
  final int? parentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseCategoryEntity({
    required this.id,
    required this.name,
    required this.businessId,
    this.code,
    this.parentId,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        businessId,
        code,
        parentId,
        createdAt,
        updatedAt,
      ];
}

/// Expense entity representing expense data
class ExpenseEntity extends Entity {
  final int? id;
  final int businessId;
  final int locationId;
  final String refNo;
  final int expenseCategoryId;
  final double totalAmount;
  final String paymentStatus;
  final String? additionalNotes;
  final int? contactId;
  final int? userId;
  final DateTime? transactionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ExpenseEntity({
    this.id,
    required this.businessId,
    required this.locationId,
    required this.refNo,
    required this.expenseCategoryId,
    required this.totalAmount,
    this.paymentStatus = 'due',
    this.additionalNotes,
    this.contactId,
    this.userId,
    this.transactionDate,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        businessId,
        locationId,
        refNo,
        expenseCategoryId,
        totalAmount,
        paymentStatus,
        additionalNotes,
        contactId,
        userId,
        transactionDate,
        createdAt,
        updatedAt,
      ];
}











