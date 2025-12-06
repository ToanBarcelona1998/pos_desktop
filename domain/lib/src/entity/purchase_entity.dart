import '../core/entity.dart';

final class PurchaseEntity extends Entity {
  final int id;
  final dynamic document;
  final String transactionDate;
  final String refNo;
  final String name;
  final String? supplierBusinessName;
  final String status;
  final String paymentStatus;
  final String finalTotal;
  final String locationName;
  final int payTermNumber;
  final String payTermType;
  final int? returnTransactionId;
  final double? amountPaid;
  final double? returnPaid;
  final int returnExists;
  final String amountReturn;
  final String addedBy;

  const PurchaseEntity({
    required this.id,
    required this.document,
    required this.transactionDate,
    required this.refNo,
    required this.name,
    this.supplierBusinessName,
    required this.status,
    required this.paymentStatus,
    required this.finalTotal,
    required this.locationName,
    required this.payTermNumber,
    required this.payTermType,
    this.returnTransactionId,
    this.amountPaid,
    this.returnPaid,
    required this.returnExists,
    required this.amountReturn,
    required this.addedBy,
  });

  @override
  List<Object?> get props => [
        id,
        document,
        transactionDate,
        refNo,
        name,
        supplierBusinessName,
        status,
        paymentStatus,
        finalTotal,
        locationName,
        payTermNumber,
        payTermType,
        returnTransactionId,
        amountPaid,
        returnPaid,
        returnExists,
        amountReturn,
        addedBy,
      ];

  PurchaseEntity copyWith({
    int? id,
    dynamic document,
    String? transactionDate,
    String? refNo,
    String? name,
    String? supplierBusinessName,
    String? status,
    String? paymentStatus,
    String? finalTotal,
    String? locationName,
    int? payTermNumber,
    String? payTermType,
    int? returnTransactionId,
    double? amountPaid,
    double? returnPaid,
    int? returnExists,
    String? amountReturn,
    String? addedBy,
  }) {
    return PurchaseEntity(
      id: id ?? this.id,
      document: document ?? this.document,
      transactionDate: transactionDate ?? this.transactionDate,
      refNo: refNo ?? this.refNo,
      name: name ?? this.name,
      supplierBusinessName: supplierBusinessName ?? this.supplierBusinessName,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      finalTotal: finalTotal ?? this.finalTotal,
      locationName: locationName ?? this.locationName,
      payTermNumber: payTermNumber ?? this.payTermNumber,
      payTermType: payTermType ?? this.payTermType,
      returnTransactionId: returnTransactionId ?? this.returnTransactionId,
      amountPaid: amountPaid ?? this.amountPaid,
      returnPaid: returnPaid ?? this.returnPaid,
      returnExists: returnExists ?? this.returnExists,
      amountReturn: amountReturn ?? this.amountReturn,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}
