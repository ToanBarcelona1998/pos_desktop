import 'package:domain/domain.dart';
import 'package:pos_final/src/core/core.dart';

import '../../base/base_event.dart';

/// POS page events
sealed class PosEvent extends BaseEvent {
  const PosEvent();
}

/// Initialize POS
class PosInitialize extends PosEvent {
  const PosInitialize();
}

/// Select location/branch
class PosSelectLocation extends PosEvent {
  final int locationId;
  const PosSelectLocation(this.locationId);
}

/// Select customer
class PosSelectCustomer extends PosEvent {
  final ContactEntity? customer;
  const PosSelectCustomer(this.customer);
}

/// Add product to cart
class PosAddToCart extends PosEvent {
  final ProductEntity product;
  final int quantity;
  const PosAddToCart({required this.product, this.quantity = 1});
}

/// Update cart item quantity
class PosUpdateCartItemQuantity extends PosEvent {
  final int productId;
  final int variationId;
  final int quantity;
  const PosUpdateCartItemQuantity({
    required this.productId,
    required this.variationId,
    required this.quantity,
  });
}

/// Remove item from cart
class PosRemoveFromCart extends PosEvent {
  final int productId;
  final int variationId;
  const PosRemoveFromCart({
    required this.productId,
    required this.variationId,
  });
}

/// Clear cart
class PosClearCart extends PosEvent {
  const PosClearCart();
}

/// Apply discount
class PosApplyDiscount extends PosEvent {
  final double amount;
  final DiscountType type;
  const PosApplyDiscount({required this.amount, required this.type});
}

/// Set tax
class PosSetTax extends PosEvent {
  final int? taxId;
  final double taxRate;
  const PosSetTax({this.taxId, required this.taxRate});
}

/// Submit sale
class PosSubmitSale extends PosEvent {
  final bool isCredit;
  final bool printInvoice;
  final PaymentMethod? paymentMethod; // Optional payment method, defaults based on isCredit
  const PosSubmitSale({
    this.isCredit = false,
    this.printInvoice = true,
    this.paymentMethod,
  });
}

/// Submit credit sale
class PosSubmitCreditSale extends PosEvent {
  const PosSubmitCreditSale();
}

/// Create quotation
class PosCreateQuotation extends PosEvent {
  const PosCreateQuotation();
}

/// Suspend sale
class PosSuspendSale extends PosEvent {
  const PosSuspendSale();
}

/// Load suspended sale
class PosLoadSuspendedSale extends PosEvent {
  final Map<String, dynamic> saleData;
  const PosLoadSuspendedSale(this.saleData);
}

/// Cancel sale
class PosCancelSale extends PosEvent {
  const PosCancelSale();
}

/// Refresh products
class PosRefreshProducts extends PosEvent {
  const PosRefreshProducts();
}

/// Load more products (pagination)
class PosLoadMoreProducts extends PosEvent {
  const PosLoadMoreProducts();
}

/// Search products
class PosSearchProducts extends PosEvent {
  final String query;
  const PosSearchProducts(this.query);
}

/// Filter by category
class PosFilterByCategory extends PosEvent {
  final int? categoryId;
  const PosFilterByCategory(this.categoryId);
}

/// Filter by brand
class PosFilterByBrand extends PosEvent {
  final int? brandId;
  const PosFilterByBrand(this.brandId);
}

/// Load customers
class PosLoadCustomers extends PosEvent {
  const PosLoadCustomers();
}

/// Search customers
class PosSearchCustomers extends PosEvent {
  final String query;
  const PosSearchCustomers(this.query);
}

/// Load suspended sells
class PosLoadSuspendedSells extends PosEvent {
  const PosLoadSuspendedSells();
}

/// Load suspended sell into POS
class PosLoadSuspendedSell extends PosEvent {
  final SellEntity sell;
  const PosLoadSuspendedSell(this.sell);
}

/// Delete suspended sell
class PosDeleteSuspendedSell extends PosEvent {
  final int sellId;
  const PosDeleteSuspendedSell(this.sellId);
}

/// Clear print invoice flag
class PosClearPrintFlag extends PosEvent {
  const PosClearPrintFlag();
}



