class Purchase {
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

  Purchase({
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

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      document: json['document'],
      transactionDate: json['transaction_date'],
      refNo: json['ref_no'],
      name: json['name'],
      supplierBusinessName: json['supplier_business_name'],
      status: json['status'],
      paymentStatus: json['payment_status'],
      finalTotal: json['final_total'],
      locationName: json['location_name'],
      payTermNumber: json['pay_term_number'] ?? 0,
      payTermType: json['pay_term_type'] ?? '',
      returnTransactionId: json['return_transaction_id'],
      amountPaid: json['amount_paid'],
      returnPaid: json['return_paid'],
      returnExists: json['return_exists'],
      amountReturn: json['amount_return'],
      addedBy: json['added_by'],
    );
  }
}

class BusinessLocations {
  Map<String, String> locations;

  BusinessLocations({
    required this.locations,
  });

  factory BusinessLocations.fromJson(Map<String, dynamic> json) {
    return BusinessLocations(
      locations: Map<String, String>.from(json),
    );
  }
}

class Suppliers {
  Map<String, String> suppliers;

  Suppliers({
    required this.suppliers,
  });

  factory Suppliers.fromJson(Map<String, dynamic> json) {
    return Suppliers(
      suppliers: Map<String, String>.from(json),
    );
  }
}

class OrderStatuses {
  Map<String, String> statuses;

  OrderStatuses({
    required this.statuses,
  });

  factory OrderStatuses.fromJson(Map<String, dynamic> json) {
    return OrderStatuses(
      statuses: Map<String, String>.from(json),
    );
  }
}

class PurchaseData {
  List<Purchase> purchases;
  BusinessLocations businessLocations;
  Suppliers suppliers;
  OrderStatuses orderStatuses;

  PurchaseData({
    required this.purchases,
    required this.businessLocations,
    required this.suppliers,
    required this.orderStatuses,
  });

  factory PurchaseData.fromJson(Map<String, dynamic> json) {
    return PurchaseData(
      purchases: List<Purchase>.from(
          json['purchases'].map((purchase) => Purchase.fromJson(purchase))),
      businessLocations:
      BusinessLocations.fromJson(json['business_locations']),
      suppliers: Suppliers.fromJson(json['suppliers']),
      orderStatuses: OrderStatuses.fromJson(json['orderStatuses']),
    );
  }
}
