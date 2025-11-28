class InvoiceType {
  // Static list of invoice types
  static const List<Map<String, dynamic>> _invoiceTypes = [
    {'value': 'final', 'label': 'final', 'is_quotation': false, 'is_suspend': false},
    {'value': 'draft', 'label': 'draft', 'is_quotation': false, 'is_suspend': false},
    {'value': 'quotation', 'label': 'quotation', 'is_quotation': true, 'is_suspend': false},
    {'value': 'suspend', 'label': 'suspend', 'is_quotation': false, 'is_suspend': true},
  ];

  // Getter for invoice types
  List<Map<String, dynamic>> get invoiceTypes => _invoiceTypes;

  // Method to get invoice type details by value
  Map<String, dynamic>? getInvoiceType(String value) {
    try {
      return _invoiceTypes.firstWhere((type) => type['value'] == value);
    } catch (e) {
      return null;
    }
  }
}