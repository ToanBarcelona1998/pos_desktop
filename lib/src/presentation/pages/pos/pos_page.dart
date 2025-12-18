import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/src/application.dart';

import 'package:pos_final/src/core/services/offline_customer_service.dart';
import 'package:pos_final/src/core/services/print_service.dart';
import 'package:pos_final/src/core/utils/window_manager_utils.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:pos_final/src/presentation/pages/pos/widgets/bar_code_listener_widget.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/localization/locale_keys.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/toast/toast_manager.dart';
import '../../widgets/dialog/dialog_provider.dart';
import 'pos_bloc.dart';
import 'pos_event.dart';
import 'pos_state.dart';
import 'widgets/pos_app_bar_widget.dart';
import 'widgets/pos_bottom_bar_widget.dart';
import 'widgets/pos_cart_widget.dart';
import 'widgets/pos_product_grid_widget.dart';
import 'widgets/pos_customer_selector_widget.dart';
import 'widgets/pos_suspended_sales_widget.dart';
import 'widgets/pos_history_sells_widget.dart';
import 'widgets/pos_payment_method_dialog.dart';

/// POS page
class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  WindowController? _customerWindowController;
  StreamSubscription ?_subscription;

  @override
  void initState() {
    super.initState();
    _subscription = onWindowsChanged.listen((_) async {
      if(_customerWindowController != null){
        try{
          final windows = await WindowController.getAll();

          if(!windows.map((e) => e.windowId).contains(_customerWindowController!.windowId)){
            _customerWindowController = null;
          }
        }catch(e){
          _customerWindowController = null;
        }
      }

    });
    context.read<PosBloc>().add(const PosInitialize());
  }

  @override
  void dispose() {
    if(_customerWindowController != null){
      _customerWindowController?.close();
    }
    _customerWindowController = null;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  Future<void> _openCustomerWindow(BuildContext context) async {
    try {
      // If window already exists, just focus it
      if (_customerWindowController != null) return;

      // Create new customer window
      final windowArgs = WindowArguments(
        type: WindowType.offlineCustomer,
        params: {

        },
      );
      _customerWindowController = await WindowManagerUtils.createNewWindow(windowArgs);
      // Broadcast current cart state immediately

      if(context.mounted){
        final state = context.read<PosBloc>().state;
        final cartSyncData = OfflineCustomerService.convertToSyncData(
          cartItems: state.cartItems,
          subtotal: state.subtotal,
          discount: state.invoiceDiscount,
          tax: state.taxAmount,
          total: state.total,
          currencySymbol: state.currencySymbol,
          customer: state.selectedCustomer,
        );
        OfflineCustomerService().broadcastCartUpdate(cartSyncData);
      }
    } catch (e) {
      // Handle error - maybe show a toast
      Logger.logE('Failed to open customer window');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<PosBloc, PosState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus ||
          previous.errorMessage != current.errorMessage ||
          previous.successMessage != current.successMessage ||
          previous.shouldPrintInvoice != current.shouldPrintInvoice ||
          previous.createdSellId != current.createdSellId,
      listener: (context, state) {
        if (state.actionStatus == PosStatus.error &&
            state.errorMessage != null) {
          final translatedMessage = l10n.translate(state.errorMessage!);
          ToastManager.showError(context, translatedMessage);
        }
        if (state.actionStatus == PosStatus.success &&
            state.successMessage != null) {
          // Translate success message key
          final translatedMessage = l10n.translate(state.successMessage!);
          ToastManager.showSuccess(context, translatedMessage);
        }

        // Handle invoice printing
        if (state.shouldPrintInvoice && state.createdSellId != null) {
          // Reset the flag immediately to prevent multiple prints
          context.read<PosBloc>().add(const PosClearPrintFlag());

          // Show print dialog
          // [TODO] Can't show print now with html
          _showPrintInvoiceDialog(
            context,
            state.products,
            state.currencySymbol,
            context.authCubit.currentUser?.fullName ?? '',
            state.createdSellId!,
            state.selectedLocationId!,
            state.taxId,
          );
        }
      },
      builder: (context, state) {
        if (state.pageStatus == PosPageStatus.loading ||
            state.pageStatus == PosPageStatus.initial) {
          return Scaffold(
            body: const AppLoadingCenter(),
          );
        }

        return RawBarCodeListenerWidget(
          onBarcodeScanned: (barcode) {
            context.read<PosBloc>().add(PosScanBarcode(barcode));
          },
          child: Scaffold(
            backgroundColor: const Color(0xffdcdee3),
            appBar: PosAppBarWidget(
              locations: state.locations,
              selectedLocationId: state.selectedLocationId,
              onOpenFullScreen: () {
                WindowManagerUtils.openFullScreen();
              },
              onLocationChanged: (locationId) {
                context.read<PosBloc>().add(PosSelectLocation(locationId));
              },
              onRefresh: () {
                context.read<PosBloc>().add(const PosRefreshProducts());
              },
              onSuspendedSales: () => showSuspendedSalesDialog(context),
              onOpenCustomerWindow: () => _openCustomerWindow(context),
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
                    onProductSearch: (query) {
                      context.read<PosBloc>().add(PosSearchProducts(query));
                    },
                    onSuspendSellSearch: (query) {
                      _searchSuspendedSell(context, query);
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
                    isLoading:
                        state.pageStatus == PosPageStatus.loadingProducts,
                    isLoadingMore:
                        state.pageStatus == PosPageStatus.loadingMore,
                    hasMore: state.hasMore,
                    cartItems: state.cartItems,
                    onProductTap: (product) {
                      context
                          .read<PosBloc>()
                          .add(PosAddToCart(product: product));
                    },
                    onSearch: (query) {
                      context.read<PosBloc>().add(PosSearchProducts(query));
                    },
                    onCategoryFilter: (categoryId) {
                      context
                          .read<PosBloc>()
                          .add(PosFilterByCategory(categoryId));
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
              isSubmitting: state.actionStatus == PosStatus.submitting,
              canSubmit: state.canSubmit,
              onCashPayment: () {
                context
                    .read<PosBloc>()
                    .add(PosSubmitSale(paymentMethod: PaymentMethod.cash));
              },
              onPaymentMethods: () {
                _showPaymentDialog(context);
              },
              onCreditPayment: () {
                context.read<PosBloc>().add(const PosSubmitCreditSale());
              },
              onDraft: () {
                context.read<PosBloc>().add(const PosCreateDraft());
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
              onPreviousPayments: () {
                _showHistorySells(context);
              },
            ),
          ),
        );
      },
    );
  }

  void _showCustomerSelector(BuildContext context) {
    final bloc = context.read<PosBloc>();
    final state = bloc.state;

    // Load customers if not loaded
    if (state.customers.isEmpty &&
        state.pageStatus != PosPageStatus.loadingCustomers) {
      bloc.add(const PosLoadCustomers());
    }

    DialogProvider.showAppDialog(
      context,
      messageWidget: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<PosBloc, PosState>(
          builder: (context, state) {
            // Filter customers by search query
            final filteredCustomers = state.customerSearchQuery.isEmpty
                ? state.customers
                : state.customers.where((customer) {
                    final query = state.customerSearchQuery.toLowerCase();
                    return customer.name.toLowerCase().contains(query) ||
                        (customer.mobile?.toLowerCase().contains(query) ??
                            false);
                  }).toList();

            return PosCustomerSelectorWidget(
              customers: filteredCustomers,
              selectedCustomer: state.selectedCustomer,
              isLoading: state.pageStatus == PosPageStatus.loadingCustomers,
              searchQuery: state.customerSearchQuery,
              onSearch: (query) {
                context.read<PosBloc>().add(PosSearchCustomers(query));
              },
              onCustomerSelected: (customer) {
                context.read<PosBloc>().add(PosSelectCustomer(customer));
                Navigator.of(context).pop();
              },
            );
          },
        ),
      ),
      actions: [],
      width: 500,
    );
  }

  /// Show print invoice dialog
  void _showPrintInvoiceDialog(
    BuildContext context,
    List<ProductEntity> products,
    String unit,
    String cashier,
    int sellId,
    int locationId,
    int? taxId,
  ) {
    final l10n = AppLocalizations.of(context);
    DialogProvider.showConfirmDialog(
      context,
      title: l10n.translate(LocaleKeys.printInvoice),
      message: l10n.translate(LocaleKeys.printInvoiceConfirmation),
      confirmText: l10n.translate(LocaleKeys.yes),
      cancelText: l10n.translate(LocaleKeys.no),
      confirmColor: Colors.blue,
      onConfirm: () async {
        try {
          await PrintService.printInvoice(
            sellId: sellId,
            taxId: taxId,
            context: context,
            name: l10n.translate(LocaleKeys.invoice),
            locationId: locationId,
            products: products,
            unit: unit,
            l10n: l10n,
            cashier: cashier,
          );
        } catch (e) {
          if (context.mounted) {
            ToastManager.showError(
              context,
              '${l10n.translate(LocaleKeys.error)}: $e',
            );
          }
        }
      },
    );
  }

  void _searchSuspendedSell(BuildContext context, String query) {
    if (query.trim().isEmpty) return;

    final bloc = context.read<PosBloc>();
    final state = bloc.state;

    // Load suspended sells if not loaded
    if (state.suspendedSells.isEmpty &&
        state.pageStatus != PosPageStatus.loadingSuspendedSells) {
      bloc.add(const PosLoadSuspendedSells());
      // Wait a bit for the data to load, then search
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          _performSuspendSellSearch(context, query);
        }
      });
    } else {
      _performSuspendSellSearch(context, query);
    }
  }

  void _performSuspendSellSearch(BuildContext context, String query) {
    final bloc = context.read<PosBloc>();
    final state = bloc.state;
    final searchQuery = query.trim().toLowerCase();

    SellEntity? foundSell;
    try {
      foundSell = state.suspendedSells.firstWhere(
        (sell) {
          final invoiceMatch =
              (sell.invoiceNo ?? '').toLowerCase() == searchQuery.toLowerCase();
          return invoiceMatch;
        },
      );
    } catch (e) {
      foundSell = null;
    }

    if (foundSell != null) {
      bloc.add(PosLoadSuspendedSell(foundSell));
    }
  }

  void _showHistorySells(BuildContext context) {
    final bloc = context.read<PosBloc>();
    final state = bloc.state;

    // Load history sells if not loaded

    if (state.pageStatus != PosPageStatus.loadingFinalSells) {
      bloc.add(const PosLoadHistorySells());
    }

    DialogProvider.showCustomDialog(
      context,
      child: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<PosBloc, PosState>(
          builder: (context, state) {
            return PosHistorySellsWidget(
              historySells: state.historySells,
              isLoading:
                  state.pageStatus == PosPageStatus.loadingSuspendedSells,
              currencySymbol: state.currencySymbol,
            );
          },
        ),
      ),
    );
  }

  void showSuspendedSalesDialog(BuildContext context) {
    final bloc = context.read<PosBloc>();
    final state = bloc.state;

    // Load suspended sells if not loaded
    if (state.suspendedSells.isEmpty &&
        state.pageStatus != PosPageStatus.loadingSuspendedSells) {
      bloc.add(const PosLoadSuspendedSells());
    }

    DialogProvider.showAppDialog(
      context,
      messageWidget: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<PosBloc, PosState>(
          builder: (context, state) {
            return PosSuspendedSalesWidget(
              suspendedSells: state.suspendedSells,
              isLoading:
                  state.pageStatus == PosPageStatus.loadingSuspendedSells,
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
      actions: [],
      width: 500,
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final bloc = context.read<PosBloc>();
    DialogProvider.showCustomDialog(
      context,
      child: BlocProvider.value(
        value: bloc,
        child: BlocBuilder<PosBloc, PosState>(
          builder: (_, state) {
            return PosPaymentMethodDialog(
              eWalletAccounts: state.eWalletAccounts,
              bankTransferAccounts: state.bankTransferAccounts,
              total: state.total,
              currencySymbol: state.currencySymbol,
            );
          },
        ),
      ),
    );
  }
}
