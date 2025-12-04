import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app_config/di.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/localization/locale_keys.dart';
import '../../widgets/app_loading.dart';
import 'pos_bloc.dart';
import 'pos_event.dart';
import 'pos_state.dart';
import 'widgets/pos_app_bar_widget.dart';
import 'widgets/pos_bottom_bar_widget.dart';
import 'widgets/pos_cart_widget.dart';
import 'widgets/pos_product_grid_widget.dart';
import 'widgets/pos_customer_selector_widget.dart';
import 'widgets/pos_suspended_sales_bottom_sheet.dart';

/// POS page
class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PosBloc(
        locationRepository: sl.get<LocationRepository>(),
        productRepository: sl.get<ProductRepository>(),
        categoryRepository: sl.get<CategoryRepository>(),
        brandRepository: sl.get<BrandRepository>(),
        contactRepository: sl.get<ContactRepository>(),
        createSellUseCase: sl.get<CreateSellUseCase>(),
        sellRepository: sl.get<SellRepository>(),
        businessRepository: sl.get<BusinessRepository>(),
      )..add(const PosInitialize()),
      child: const _PosView(),
    );
  }
}

class _PosView extends StatelessWidget {
  const _PosView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<PosBloc, PosState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure ||
          previous.successMessage != current.successMessage,
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.failure!.message),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
        if (state.successMessage != null) {
          // Translate success message key
          final translatedMessage = l10n.translate(state.successMessage!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(translatedMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.translate(LocaleKeys.pos)),
            ),
            body: const AppLoadingCenter(),
          );
        }

        return Scaffold(
          appBar: PosAppBarWidget(
            locations: state.locations,
            selectedLocationId: state.selectedLocationId,
            onLocationChanged: (locationId) {
              context.read<PosBloc>().add(PosSelectLocation(locationId));
            },
            onRefresh: () {
              context.read<PosBloc>().add(const PosRefreshProducts());
            },
            onSuspendedSales: () => _showSuspendedSalesBottomSheet(context),
          ),
          body: Row(
            children: [
              // Cart section (left)
              Expanded(
                flex: 3,
                child: PosCartWidget(
                  customer: state.selectedCustomer,
                  cartItems: state.cartItems,
                  currencySymbol: state.currencySymbol,
                  subtotal: state.subtotal,
                  discount: state.invoiceDiscount,
                  tax: state.taxAmount,
                  total: state.total,
                  onCustomerSelect: () => _showCustomerSelector(context),
                  onQuantityChanged: (productId, variationId, quantity) {
                    context.read<PosBloc>().add(PosUpdateCartItemQuantity(
                          productId: productId,
                          variationId: variationId,
                          quantity: quantity,
                        ));
                  },
                  onRemoveItem: (productId, variationId) {
                    context.read<PosBloc>().add(PosRemoveFromCart(
                          productId: productId,
                          variationId: variationId,
                        ));
                  },
                ),
              ),
              // Product grid section (right)
              Expanded(
                flex: 2,
                child: PosProductGridWidget(
                  products: state.filteredProducts,
                  categories: state.categories,
                  brands: state.brands,
                  selectedCategoryId: state.selectedCategoryId,
                  selectedBrandId: state.selectedBrandId,
                  searchQuery: state.searchQuery,
                  isLoading: state.isLoadingProducts,
                  isLoadingMore: state.isLoadingMore,
                  hasMore: state.hasMore,
                  cartItems: state.cartItems,
                  onProductTap: (product) {
                    context.read<PosBloc>().add(PosAddToCart(product: product));
                  },
                  onSearch: (query) {
                    context.read<PosBloc>().add(PosSearchProducts(query));
                  },
                  onCategoryFilter: (categoryId) {
                    context.read<PosBloc>().add(PosFilterByCategory(categoryId));
                  },
                  onBrandFilter: (brandId) {
                    context.read<PosBloc>().add(PosFilterByBrand(brandId));
                  },
                  onLoadMore: () {
                    context.read<PosBloc>().add(const PosLoadMoreProducts());
                  },
                  onRefresh: () {
                    context.read<PosBloc>().add(const PosRefreshProducts());
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: PosBottomBarWidget(
            total: state.total,
            currencySymbol: state.currencySymbol,
            isSubmitting: state.isSubmitting,
            canSubmit: state.canSubmit,
            onCashPayment: () {
              context.read<PosBloc>().add(const PosSubmitSale());
            },
            onCreditPayment: () {
              context.read<PosBloc>().add(const PosSubmitCreditSale());
            },
            onQuotation: () {
              context.read<PosBloc>().add(const PosCreateQuotation());
            },
            onSuspend: () {
              context.read<PosBloc>().add(const PosSuspendSale());
            },
            onCancel: () {
              context.read<PosBloc>().add(const PosCancelSale());
            },
          ),
        );
      },
    );
  }

  void _showCustomerSelector(BuildContext context) {
    final bloc = context.read<PosBloc>();
    final state = bloc.state;

    // Load customers if not loaded
    if (state.customers.isEmpty && !state.isLoadingCustomers) {
      bloc.add(const PosLoadCustomers());
    }

    showDialog(
      context: context,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<PosBloc, PosState>(
          builder: (context, state) {
            // Filter customers by search query
            final filteredCustomers = state.customerSearchQuery.isEmpty
                ? state.customers
                : state.customers.where((customer) {
                    final query = state.customerSearchQuery.toLowerCase();
                    return customer.name.toLowerCase().contains(query) ||
                        (customer.mobile?.toLowerCase().contains(query) ?? false);
                  }).toList();

            return PosCustomerSelectorWidget(
              customers: filteredCustomers,
              selectedCustomer: state.selectedCustomer,
              isLoading: state.isLoadingCustomers,
              searchQuery: state.customerSearchQuery,
              onSearch: (query) {
                context.read<PosBloc>().add(PosSearchCustomers(query));
              },
              onCustomerSelected: (customer) {
                context.read<PosBloc>().add(PosSelectCustomer(customer));
              },
            );
          },
        ),
      ),
    );
  }

  void _showSuspendedSalesBottomSheet(BuildContext context) {
    final bloc = context.read<PosBloc>();
    final state = bloc.state;

    // Load suspended sells if not loaded
    if (state.suspendedSells.isEmpty && !state.isLoadingSuspendedSells) {
      bloc.add(const PosLoadSuspendedSells());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: BlocBuilder<PosBloc, PosState>(
          builder: (context, state) {
            return PosSuspendedSalesBottomSheet(
              suspendedSells: state.suspendedSells,
              isLoading: state.isLoadingSuspendedSells,
              onContinue: (sell) {
                context.read<PosBloc>().add(PosLoadSuspendedSell(sell));
              },
              onDelete: (sellId) {
                context.read<PosBloc>().add(PosDeleteSuspendedSell(sellId));
              },
            );
          },
        ),
      ),
    );
  }
}
