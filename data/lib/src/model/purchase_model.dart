import 'base_model.dart';

/// Purchase data model
class PurchaseModel extends BaseModel {
  final int id;
  final int businessId;
  final int locationId;
  final int contactId;
  final String refNo;
  final String transactionDate;
  final double totalBeforeTax;
  final double taxAmount;
  final double finalTotal;
  final String status;
  final String paymentStatus;
  final String? additionalNotes;
  final String? createdAt;
  final String? updatedAt;

  const PurchaseModel({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.contactId,
    required this.refNo,
    required this.transactionDate,
    required this.totalBeforeTax,
    required this.taxAmount,
    required this.finalTotal,
    required this.status,
    required this.paymentStatus,
    this.additionalNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    return PurchaseModel(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      locationId: json['location_id'] as int,
      contactId: json['contact_id'] as int,
      refNo: json['ref_no'] as String? ?? '',
      transactionDate: json['transaction_date'] as String,
      totalBeforeTax: _parseDouble(json['total_before_tax']),
      taxAmount: _parseDouble(json['tax_amount']),
      finalTotal: _parseDouble(json['final_total']),
      status: json['status'] as String? ?? 'received',
      paymentStatus: json['payment_status'] as String? ?? 'due',
      additionalNotes: json['additional_notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'location_id': locationId,
      'contact_id': contactId,
      'ref_no': refNo,
      'transaction_date': transactionDate,
      'total_before_tax': totalBeforeTax,
      'tax_amount': taxAmount,
      'final_total': finalTotal,
      'status': status,
      'payment_status': paymentStatus,
      'additional_notes': additionalNotes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}









