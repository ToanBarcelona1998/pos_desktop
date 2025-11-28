part of 'checkout_cubit.dart';

class CheckoutState extends Equatable {
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> paymentMethods;
  final List<Map<String, dynamic>> paymentAccounts;
  final Map<dynamic,dynamic> arguments;
  final List<int> deletedPaymentIds;
  final double totalPaying;
  final double invoiceAmount;
  final double pendingAmount;
  final double changeReturn;
  final String symbol;
  final String transactionDate;
  final String invoiceType;
  final bool isLoading;
  final bool saleCreated;
  final bool printInvoice;
  final bool printWebInvoice;
  final String? saleNote;
  final String? staffNote;
  final String? shippingDetails;
  final double? shippingCharges;
  final int? sellId;
  final String? error;

  const CheckoutState({
    this.payments = const [],
    this.paymentMethods = const [],
    this.paymentAccounts = const [{'id': null, 'name': 'None'}],
    this.deletedPaymentIds = const [],
    this.totalPaying = 0.0,
    this.invoiceAmount = 0.0,
    this.pendingAmount = 0.0,
    this.changeReturn = 0.0,
    this.symbol = '',
    this.transactionDate = '',
    this.invoiceType = 'Mobile',
    this.isLoading = false,
    this.saleCreated = false,
    this.printInvoice = true,
    this.printWebInvoice = false,
    this.saleNote,
    this.staffNote,
    this.shippingDetails,
    this.shippingCharges,
    this.sellId,
    this.error,
    this.arguments = const{}
  });

  CheckoutState copyWith({
    List<Map<String, dynamic>>? payments,
    List<Map<String, dynamic>>? paymentMethods,
    List<Map<String, dynamic>>? paymentAccounts,
    Map<dynamic,dynamic>? arguments,
    List<int>? deletedPaymentIds,
    double? totalPaying,
    double? invoiceAmount,
    double? pendingAmount,
    double? changeReturn,
    String? symbol,
    String? transactionDate,
    String? invoiceType,
    bool? isLoading,
    bool? saleCreated,
    bool? printInvoice,
    bool? printWebInvoice,
    String? sellNote,
    String? staffNote,
    String? shippingDetails,
    double? shippingCharges,
    int? sellId,
    String? error,
  }) {
    return CheckoutState(
      payments: payments ?? this.payments,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      paymentAccounts: paymentAccounts ?? this.paymentAccounts,
      deletedPaymentIds: deletedPaymentIds ?? this.deletedPaymentIds,
      totalPaying: totalPaying ?? this.totalPaying,
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      changeReturn: changeReturn ?? this.changeReturn,
      symbol: symbol ?? this.symbol,
      transactionDate: transactionDate ?? this.transactionDate,
      invoiceType: invoiceType ?? this.invoiceType,
      isLoading: isLoading ?? this.isLoading,
      saleCreated: saleCreated ?? this.saleCreated,
      printInvoice: printInvoice ?? this.printInvoice,
      printWebInvoice: printWebInvoice ?? this.printWebInvoice,
      saleNote: sellNote ?? saleNote,
      staffNote: staffNote ?? this.staffNote,
      shippingDetails: shippingDetails ?? this.shippingDetails,
      shippingCharges: shippingCharges ?? this.shippingCharges,
      sellId: sellId ?? this.sellId,
      error: error ?? this.error,
      arguments: arguments ?? this.arguments,
    );
  }

  @override
  List<Object?> get props => [
    payments,
    paymentMethods,
    paymentAccounts,
    deletedPaymentIds,
    totalPaying,
    invoiceAmount,
    pendingAmount,
    changeReturn,
    symbol,
    transactionDate,
    invoiceType,
    isLoading,
    saleCreated,
    printInvoice,
    printWebInvoice,
    saleNote,
    staffNote,
    shippingDetails,
    shippingCharges,
    sellId,
    error,
  ];
}