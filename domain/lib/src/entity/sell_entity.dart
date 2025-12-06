import '../core/entity.dart';

final class SellEntity extends Entity {
  final int id;
  final String? transactionDate;
  final String? invoiceNo;
  final int? contactId;
  final int? locationId;
  final String? status;
  final int? taxRateId;
  final double? discountAmount;
  final String? discountType;
  final String? saleNote;
  final String? staffNote;
  final bool isQuotation;
  final bool isSuspend;
  final double? invoiceAmount;
  final double? changeReturn;
  final double? pendingAmount;
  final bool isSynced;
  final int? transactionId;
  final String? invoiceUrl;
  final List<SellLineEntity> sellLines;
  final List<SellPaymentEntity> payments;

  const SellEntity({
    required this.id,
    this.transactionDate,
    this.invoiceNo,
    this.contactId,
    this.locationId,
    this.status,
    this.taxRateId,
    this.discountAmount,
    this.discountType,
    this.saleNote,
    this.staffNote,
    this.isQuotation = false,
    this.isSuspend = false,
    this.invoiceAmount,
    this.changeReturn,
    this.pendingAmount,
    this.isSynced = false,
    this.transactionId,
    this.invoiceUrl,
    this.sellLines = const [],
    this.payments = const [],
  });

  @override
  List<Object?> get props => [
        id,
        invoiceNo,
        contactId,
        locationId,
        status,
      ];

  SellEntity copyWith({
    int? id,
    String? transactionDate,
    String? invoiceNo,
    int? contactId,
    int? locationId,
    String? status,
    int? taxRateId,
    double? discountAmount,
    String? discountType,
    String? saleNote,
    String? staffNote,
    bool? isQuotation,
    bool? isSuspend,
    double? invoiceAmount,
    double? changeReturn,
    double? pendingAmount,
    bool? isSynced,
    int? transactionId,
    String? invoiceUrl,
    List<SellLineEntity>? sellLines,
    List<SellPaymentEntity>? payments,
  }) {
    return SellEntity(
      id: id ?? this.id,
      transactionDate: transactionDate ?? this.transactionDate,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      contactId: contactId ?? this.contactId,
      locationId: locationId ?? this.locationId,
      status: status ?? this.status,
      taxRateId: taxRateId ?? this.taxRateId,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      saleNote: saleNote ?? this.saleNote,
      staffNote: staffNote ?? this.staffNote,
      isQuotation: isQuotation ?? this.isQuotation,
      isSuspend: isSuspend ?? this.isSuspend,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      changeReturn: changeReturn ?? this.changeReturn,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      isSynced: isSynced ?? this.isSynced,
      transactionId: transactionId ?? this.transactionId,
      invoiceUrl: invoiceUrl ?? this.invoiceUrl,
      sellLines: sellLines ?? this.sellLines,
      payments: payments ?? this.payments,
    );
  }
}

final class SellLineEntity extends Entity {
  final int id;
  final int? sellId;
  final int? productId;
  final int? variationId;
  final double? quantity;
  final double? unitPrice;
  final int? taxRateId;
  final double? discountAmount;
  final String? discountType;
  final String? note;

  const SellLineEntity({
    required this.id,
    this.sellId,
    this.productId,
    this.variationId,
    this.quantity,
    this.unitPrice,
    this.taxRateId,
    this.discountAmount,
    this.discountType,
    this.note,
  });

  @override
  List<Object?> get props => [id, sellId, productId, variationId];
}

final class SellPaymentEntity extends Entity {
  final int id;
  final int? sellId;
  final int? paymentId;
  final String? method;
  final double? amount;
  final String? note;
  final int? accountId;
  final bool isReturn;
  final String? transactionDate;

  const SellPaymentEntity({
    required this.id,
    this.sellId,
    this.paymentId,
    this.method,
    this.amount,
    this.note,
    this.accountId,
    this.isReturn = false,
    this.transactionDate,
  });

  @override
  List<Object?> get props => [id, sellId, method, amount];
}














