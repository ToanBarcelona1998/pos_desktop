import 'base_model.dart';

/// Sell data model
class SellModel extends BaseModel {
  final int id;
  final int businessId;
  final int locationId;
  final int? contactId;
  final String? invoiceNo;
  final String transactionDate;
  final double totalBeforeTax;
  final double taxAmount;
  final double discount;
  final double finalTotal;
  final String status;
  final String paymentStatus;
  final int isQuotation;
  final int isSuspend;
  final String? invoiceUrl;
  final double? changeReturn;
  final List<dynamic>? paymentLines;
  final String? createdAt;
  final String? updatedAt;

  const SellModel({
    required this.id,
    required this.businessId,
    required this.locationId,
    this.contactId,
    this.invoiceNo,
    required this.transactionDate,
    required this.totalBeforeTax,
    required this.taxAmount,
    required this.discount,
    required this.finalTotal,
    required this.status,
    required this.paymentStatus,
    this.isQuotation = 0,
    this.isSuspend = 0,
    this.invoiceUrl,
    this.changeReturn,
    this.paymentLines,
    this.createdAt,
    this.updatedAt,
  });

  factory SellModel.fromJson(Map<String, dynamic> json) {
    return SellModel(
      id: json['id'] as int,
      businessId: json['business_id'] as int,
      locationId: json['location_id'] as int,
      contactId: json['contact_id'] as int?,
      invoiceNo: json['invoice_no'] as String?,
      transactionDate: json['transaction_date'] as String,
      totalBeforeTax: _parseDouble(json['total_before_tax']),
      taxAmount: _parseDouble(json['tax_amount']),
      discount: _parseDouble(json['discount_amount']),
      finalTotal: _parseDouble(json['final_total']),
      status: json['status'] as String? ?? 'final',
      paymentStatus: json['payment_status'] as String? ?? 'due',
      isQuotation: json['is_quotation'] as int? ?? 0,
      isSuspend: json['is_suspend'] as int? ?? 0,
      invoiceUrl: json['invoice_url'] as String?,
      changeReturn: _parseDouble(json['change_return']),
      paymentLines: json['payment_lines'] as List<dynamic>?,
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
      'invoice_no': invoiceNo,
      'transaction_date': transactionDate,
      'total_before_tax': totalBeforeTax,
      'tax_amount': taxAmount,
      'discount_amount': discount,
      'final_total': finalTotal,
      'status': status,
      'payment_status': paymentStatus,
      'is_quotation': isQuotation,
      'is_suspend': isSuspend,
      'invoice_url': invoiceUrl,
      'change_return': changeReturn,
      'payment_lines': paymentLines,
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








