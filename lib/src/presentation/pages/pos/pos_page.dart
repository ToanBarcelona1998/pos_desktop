import 'dart:async';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos_final/src/application.dart';
import 'package:pos_final/src/core/core.dart';
import 'package:pos_final/src/core/services/barcode_scan_service.dart';

import 'package:pos_final/src/core/services/offline_customer_service.dart';
import 'package:pos_final/src/core/services/print_service.dart';
import 'package:pos_final/src/core/services/currency_converter_service.dart';
import 'package:pos_final/src/core/utils/window_manager_utils.dart';
import 'package:pos_final/src/core/utils/window_manager_abstract.dart' as wm_abstract;
import 'package:pos_final/src/core/utils/platform_helper.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart' show onWindowsChanged;
import '../../../../app_config/di.dart';
import '../../../application/auth/auth_cubit.dart';
import '../../../application/auth/auth_state.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/localization/locale_keys.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/toast/toast_manager.dart';
import '../../widgets/dialog/dialog_provider.dart';
import '../../widgets/dialog/currency_selection_dialog.dart';
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
import 'cashier_session/cashier_session_cubit.dart';
import 'cashier_session/cashier_session_state.dart';
import 'widgets/cashier_checkin_dialog.dart';
import 'widgets/cashier_checkout_dialog.dart';

/// POS page
class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  wm_abstract.WindowManagerAbstract? _windowManager;
  StreamSubscription? _windowStatusSubscription;
  StreamSubscription? _subscription;

  late final BarcodeScannerService scanner;
  late final WindowActiveObserver windowObserver;
  
  bool _cashierSessionInitialized = false; // Track initialization
  PosState? _previousPosState; // Track previous POS state for location change detection

  @override
  void initState() {
    super.initState();
    scanner = BarcodeScannerService(
      onBarcodeScanned: (barcode) {
        context.read<PosBloc>().add(PosScanBarcode(barcode));
      },
    );
    windowObserver = WindowActiveObserver()..init();

    // Set initial enabled state based on current window active state
    scanner.setEnabled(windowObserver.isActive.value);
    
    // Start scanner after ensuring it's enabled
    scanner.start();

    windowObserver.isActive.addListener(() {
      scanner.setEnabled(windowObserver.isActive.value);
    });

    // Initialize window manager (only on supported platforms)
    try {
      if (PlatformHelper.isDesktop || PlatformHelper.isAndroid) {
        _windowManager = WindowManagerUtils.getWindowManager();
        
        // Listen to window status changes
        _windowStatusSubscription = _windowManager!.windowStatusStream.listen((status) {
          if (mounted && !status.isOpen) {
            context.read<PosBloc>().add(PosChangeCustomerWindowStatus(false));
          }
        });
      }
    } catch (e) {
      // Platform not supported for multi-window, ignore
      Logger.logI('Window manager not available on this platform');
    }

    // Desktop-only: Legacy window change listener (for backward compatibility)
    if (PlatformHelper.isDesktop) {
      _subscription = onWindowsChanged.listen((_) async {
        if (_windowManager != null) {
          final isOpen = await _windowManager!.isCustomerWindowOpen();
          if (!isOpen && mounted) {
            context.read<PosBloc>().add(PosChangeCustomerWindowStatus(false));
          }
        }
      });
    }

    context.read<PosBloc>().add(const PosInitialize());
  }

  @override
  void dispose() {
    scanner.stop();
    windowObserver.dispose();
    
    _windowStatusSubscription?.cancel();
    _windowStatusSubscription = null;
    
    try {
      _windowManager?.closeCustomerWindow();
    } catch (_) {}
    
    _windowManager?.dispose();
    _windowManager = null;

    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  Future<void> _openCustomerWindow(BuildContext context) async {
    if (_windowManager == null) {
      if (mounted) {
        ToastManager.showError(context, 'Multi-window not supported on this platform');
      }
      return;
    }

    try {
      final isOpen = await _windowManager!.isCustomerWindowOpen();
      
      if (isOpen) {
        await _windowManager!.showCustomerWindow();
        return;
      }

      // Get current cart state
      final state = context.read<PosBloc>().state;
      final cartSyncData = OfflineCustomerService.convertToSyncData(
        cartItems: state.cartItems,
        subtotal: state.subtotal,
        discount: state.invoiceDiscount,
        tax: state.taxAmount,
        total: state.total,
        currencySymbol: state.currencySymbol,
        customer: state.selectedCustomer,
        paymentMethod: state.selectedPaymentMethod,
        paymentAccount: state.selectedPaymentAccount,
      );

      // Open customer window
      await _windowManager!.openCustomerWindow(
        type: wm_abstract.WindowType.offlineCustomer,
        params: {
          'type': wm_abstract.WindowType.offlineCustomer.type,
        },
      );

      if (context.mounted) {
        context.read<PosBloc>().add(PosChangeCustomerWindowStatus(true));
      }

      // Sync cart data after opening window (with small delay to ensure window is ready)
      await Future.delayed(const Duration(milliseconds: 100));
      await _windowManager!.syncCartData(cartSyncData.toJson());
    } catch (e) {
      Logger.logE('Failed to open customer window', e);
      if (mounted) {
        ToastManager.showError(context, 'Failed to open customer window: ${e.toString()}');
      }
    }
  }

  Future<void> _syncCartDataToCustomerWindow(PosState state) async {
    if (_windowManager == null) return;

    try {
      final isOpen = await _windowManager!.isCustomerWindowOpen();
      if (!isOpen) return;

      final cartSyncData = OfflineCustomerService.convertToSyncData(
        cartItems: state.cartItems,
        subtotal: state.subtotal,
        discount: state.invoiceDiscount,
        tax: state.taxAmount,
        total: state.total,
        currencySymbol: state.currencySymbol,
        customer: state.selectedCustomer,
        paymentMethod: state.selectedPaymentMethod,
        paymentAccount: state.selectedPaymentAccount,
      );

      await _windowManager!.syncCartData(cartSyncData.toJson());
    } catch (e) {
      // Ignore sync errors silently
      Logger.logI('Failed to sync cart data to customer window: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<CashierSessionCubit, CashierSessionState>(
          listenWhen: (previous, current) =>
              previous.showCheckInDialog != current.showCheckInDialog ||
              previous.showCheckOutDialog != current.showCheckOutDialog ||
              previous.checkOutSuccess != current.checkOutSuccess ||
              previous.errorMessage != current.errorMessage,
          listener: (context, sessionState) {
            // Show check-in dialog
            if (sessionState.showCheckInDialog) {
              _showCheckInDialog(context);
            }

            // Show check-out dialog
            if (sessionState.showCheckOutDialog) {
              _showCheckOutDialog(context, sessionState);
            }

            // Logout after successful check-out
            if (sessionState.checkOutSuccess) {
              _logoutAfterCheckOut(context);
            }

            // Show error if any
            if (sessionState.errorMessage != null) {
              ToastManager.showError(context, sessionState.errorMessage!);
            }
          },
          builder: (context, sessionState) {
            return BlocConsumer<PosBloc, PosState>(
              listenWhen: (previous, current) {
                _previousPosState = previous;
                return previous.actionStatus != current.actionStatus ||
                    previous.errorMessage != current.errorMessage ||
                    previous.successMessage != current.successMessage ||
                    previous.shouldPrintInvoice != current.shouldPrintInvoice ||
                    previous.createdSellId != current.createdSellId ||
                    previous.cartItems != current.cartItems ||
                    previous.subtotal != current.subtotal ||
                    previous.invoiceDiscount != current.invoiceDiscount ||
                    previous.taxAmount != current.taxAmount ||
                    previous.total != current.total ||
                    previous.selectedCustomer != current.selectedCustomer ||
                    previous.selectedPaymentMethod != current.selectedPaymentMethod ||
                    previous.selectedPaymentAccount != current.selectedPaymentAccount ||
                    // Listen when POS is ready and location is selected
                    (previous.pageStatus == PosPageStatus.loading &&
                     current.pageStatus == PosPageStatus.idle) ||
                    (previous.selectedLocationId != current.selectedLocationId &&
                     current.selectedLocationId != null);
              },
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

                // Sync cart data to customer window when cart changes
                if (_windowManager != null) {
                  _syncCartDataToCustomerWindow(state);
                }

                // Initialize cashier session when POS is ready and location is available
                if (!_cashierSessionInitialized &&
                    state.pageStatus == PosPageStatus.idle &&
                    state.selectedLocationId != null) {
                  _initializeCashierSession(context, state.selectedLocationId!);
                }

                // Reset flag when location changes to allow re-initialization
                if (_previousPosState != null &&
                    _previousPosState!.selectedLocationId != state.selectedLocationId &&
                    state.selectedLocationId != null) {
                  _cashierSessionInitialized = false;

                  // If there's an active session from previous location, log it
                  final cashierSessionCubit = context.read<CashierSessionCubit>();
                  final sessionState = cashierSessionCubit.state;

                  if (sessionState.activeSession != null) {
                    Logger.logI('Location changed but active session exists for previous location');
                  }

                  // Re-initialize for new location
                  _initializeCashierSession(context, state.selectedLocationId!);
                }
              },
          builder: (context, state) {
            if (state.pageStatus == PosPageStatus.loading ||
                state.pageStatus == PosPageStatus.initial) {
              return Scaffold(
                body: const AppLoadingCenter(),
              );
            }

            return Scaffold(
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
                onCloseSession: () {
                  final cashierSessionCubit = context.read<CashierSessionCubit>();
                  final sessionState = cashierSessionCubit.state;

                  // Check if there's an active session
                  if (sessionState.activeSession == null) {
                    ToastManager.showError(
                      context,
                      'No active session to close',
                    );
                    return;
                  }

                  // Show check-out dialog
                  cashierSessionCubit.showCheckOutDialog();
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
            );
          },
            );
          },
        );
  }

  Future<void> _initializeCashierSession(
    BuildContext context,
    int locationId,
  ) async {
    if (_cashierSessionInitialized) return; // Prevent multiple calls
    
    final authCubit = context.read<AuthCubit>();
    final user = authCubit.state is Authenticated 
        ? (authCubit.state as Authenticated).user 
        : null;
    
    if (user == null) {
      Logger.logI('User not authenticated, skipping cashier session init');
      return;
    }
    
    _cashierSessionInitialized = true; // Mark as initialized
    
    final cashierSessionCubit = context.read<CashierSessionCubit>();
    await cashierSessionCubit.initialize(
      userId: user.id,
      locationId: locationId,
    );
  }

  void _showCheckInDialog(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final posBloc = context.read<PosBloc>();
    final cashierSessionCubit = context.read<CashierSessionCubit>();
    
    final user = authCubit.state is Authenticated 
        ? (authCubit.state as Authenticated).user 
        : null;
    final locationId = posBloc.state.selectedLocationId;
    
    if (user == null || locationId == null) {
      ToastManager.showError(context, 'User or location not available');
      return;
    }
    
    DialogProvider.showCustomDialog(
      context,
      child: CashierCheckInDialog(
        onCheckIn: (amount) async {
          await cashierSessionCubit.checkIn(
            userId: user.id,
            locationId: locationId,
            amount: amount,
          );
        },
      ),
    );
  }

  void _showCheckOutDialog(
    BuildContext context,
    CashierSessionState sessionState,
  ) {
    if (sessionState.activeSession == null) {
      return;
    }
    
    final authCubit = context.read<AuthCubit>();
    final posBloc = context.read<PosBloc>();
    final cashierSessionCubit = context.read<CashierSessionCubit>();
    
    final user = authCubit.state is Authenticated 
        ? (authCubit.state as Authenticated).user 
        : null;
    final locationId = posBloc.state.selectedLocationId;
    final location = posBloc.state.locations
        .where((l) => l.id == locationId)
        .isNotEmpty
        ? posBloc.state.locations.firstWhere((l) => l.id == locationId)
        : null;
    
    if (user == null || locationId == null) {
      ToastManager.showError(context, 'User or location not available');
      return;
    }
    
    DialogProvider.showCustomDialog(
      context,
      barrierDismissible: false,
      child: BlocProvider.value(
        value: cashierSessionCubit,
        child: CashierCheckOutDialog(
          session: sessionState.activeSession!,
          cashierName: _getUserDisplayName(user),
          locationName: location?.name ?? 'Location',
          onCheckOut: ({
            required double closingAmount,
            required double closingAmountOnStaff,
            required double totalCardSlips,
            required double totalCheques,
            required String closingNote,
            required Map<String, int> denominations,
          }) async {
            await cashierSessionCubit.checkOut(
              closingAmount: closingAmount,
              closingAmountOnStaff: closingAmountOnStaff,
              totalCardSlips: totalCardSlips,
              totalCheques: totalCheques,
              closingNote: closingNote,
              denominations: denominations,
              userId: user.id,
              locationId: locationId,
            );
          },
        ),
      ),
    );
  }

  Future<void> _logoutAfterCheckOut(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    
    // Logout app - this will emit Unauthenticated state
    // pos_online_page will automatically handle webview logout 
    // when it detects Unauthenticated state in its BlocListener
    await authCubit.logout();
  }

  String _getUserDisplayName(UserEntity user) {
    if (user.firstName != null || user.lastName != null) {
      return '${user.firstName ?? ''} ${user.lastName ?? ''}'.trim();
    }
    return user.username ?? 'Cashier';
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
      confirmColor: AppThemes.light.primaryColor,
      onConfirm: () async {
        try {
          // Show currency selection dialog
          final currencyConverter = sl.get<CurrencyConverterService>();
          final exchangeRate = await currencyConverter.getCurrentRate();

          final selectedCurrency = await showDialog<String>(
            context: context,
            builder: (context) => CurrencySelectionDialog(
              exchangeRate: exchangeRate,
            ),
          );

          if (selectedCurrency == null) return; // User cancelled

          // Validate exchange rate if USD selected
          if (selectedCurrency == 'USD') {
            if (exchangeRate == null || exchangeRate.conversionRate <= 0) {
              if (context.mounted) {
                ToastManager.showError(
                  context,
                  l10n.translate(LocaleKeys.error),
                );
              }
              return;
            }
          }

          await PrintService.printInvoice(
            sellId: sellId,
            taxId: taxId,
            context: context,
            name: l10n.translate(LocaleKeys.invoice),
            locationId: locationId,
            products: products,
            unit: selectedCurrency,
            l10n: l10n,
            cashier: cashier,
            currency: selectedCurrency,
            exchangeRate: exchangeRate,
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

    bloc.add(const PosLoadSuspendedSells());

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
      barrierDismissible: false,
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
