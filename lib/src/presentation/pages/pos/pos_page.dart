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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n?.translate(LocaleKeys.pos) ?? 'POS'),
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
    // TODO: Show customer selector dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Customer'),
        content: const Text('Customer selector will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
