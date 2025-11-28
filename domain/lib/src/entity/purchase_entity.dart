final class PurchaseEntity {
  int id;
  dynamic document;
  String transactionDate;
  String refNo;
  String name;
  dynamic supplierBusinessName;
  String status;
  String paymentStatus;
  String finalTotal;
  String locationName;
  int payTermNumber;
  String payTermType;
  dynamic returnTransactionId;
  dynamic amountPaid;
  dynamic returnPaid;
  int returnExists;
  String amountReturn;
  String addedBy;

  PurchaseEntity({
    required this.id,
    required this.document,
    required this.transactionDate,
    required this.refNo,
    required this.name,
    required this.supplierBusinessName,
    required this.status,
    required this.paymentStatus,
    required this.finalTotal,
    required this.locationName,
    required this.payTermNumber,
    required this.payTermType,
    required this.returnTransactionId,
    required this.amountPaid,
    required this.returnPaid,
    required this.returnExists,
    required this.amountReturn,
    required this.addedBy,
  });
}