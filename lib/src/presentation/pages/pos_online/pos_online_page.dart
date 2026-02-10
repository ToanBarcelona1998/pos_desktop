import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' hide WindowType;
import 'package:pos_final/app_config/app_config.dart';
import 'package:pos_final/app_config/di.dart';
import 'package:pos_final/src/application.dart';
import 'package:pos_final/src/application/application.dart';
import 'package:pos_final/src/core/core.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_observer.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_subject.dart';
import 'package:pos_final/src/core/utils/window_manager_utils.dart';
import 'package:pos_final/src/presentation/pages/pos/cashier_session/cashier_session_state.dart';
import 'package:pos_final/src/presentation/widgets/dialog/dialog_provider.dart';
import 'package:pos_final/src/presentation/widgets/dialog/base_dialog_widget.dart';
import 'package:data/data.dart';
import 'package:pos_final/src/presentation/pages/pos/cashier_session/cashier_session_cubit.dart';

import '../../presentation.dart';

class PosOnlinePage extends StatefulWidget {
  const PosOnlinePage({super.key});

  @override
  State<PosOnlinePage> createState() => _PosOnlinePageState();
}

class _PosOnlinePageState extends State<PosOnlinePage>
    with  WidgetsBindingObserver implements NetworkStatusObserver{
  WindowController? _customerWindowController;

  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
    supportMultipleWindows: true,
    javaScriptCanOpenWindowsAutomatically: false,
    useShouldOverrideUrlLoading: true,
    disableContextMenu: false
  );

  late PosOnlineBloc _posOnlineBloc;

  late NetworkStatusSubject _networkStatusSubject;

  bool _isFirstLoad = true;
  bool _syncDialogShowing = false;
  bool _popupOfflineIsShowed = false;
  bool _offlineWebviewShown = false;
  bool _isLoggingIn = false; // Flag to prevent logout during login process

  final AppConfig _appConfig = sl.get<AppConfig>();
  final WebViewEnvironment? _webViewEnvironment =
      sl.getOrNull<WebViewEnvironment>();

  final WindowsDeviceInfo? _windowsDeviceInfo =
      sl.getOrNull<WindowsDeviceInfo>();

  Map<String, String> get _requiredHeaders => {
        'X-Oman-Application': _appConfig.webHeader,
      };

  final String _postAppReadySource = '''
  if (window.handleAppRequest) {
    window.handleAppRequest('appReady');
  }
  ''';

  final String _logoutScript = '''
  if (window.handleAppRequest) {
    window.handleAppRequest('logout');
  }
  ''';

  String _postHardWareId(String hardwareId) => '''
  if (window.handleAppRequest) {
    window.handleAppRequest('postHardwareID', ${jsonEncode({
            'hardwareId': hardwareId
          })});
  }
  ''';

  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    _posOnlineBloc = PosOnlineBloc(
      authCubit: context.read<AuthCubit>(),
      syncService: sl.get<SystemSyncService>(),
      sellRepository: sl.get<SellRepository>(),
    )..add(const PosOnlineInitialize());
    _networkStatusSubject = NetworkStatusSubject();
    _networkStatusSubject.attach(this);
    _networkStatusSubject.listenNetworkChanged();
    super.initState();
  }

  @override
  void dispose() {
    try {
      _customerWindowController?.close();
    } catch (_) {}
    _customerWindowController = null;
    _networkStatusSubject.detach(this);
    _networkStatusSubject.close();
    webViewController?.dispose();
    _posOnlineBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => _posOnlineBloc),
        BlocProvider(
          create: (context) => PosBloc(
            locationRepository: sl.get<LocationRepository>(),
            productRepository: sl.get<ProductRepository>(),
            categoryRepository: sl.get<CategoryRepository>(),
            brandRepository: sl.get<BrandRepository>(),
            contactRepository: sl.get<ContactRepository>(),
            createSellUseCase: sl.get<CreateSellUseCase>(),
            getSuspendedSellsUseCase: sl.get<GetSuspendedSellsUseCase>(),
            deleteSellUseCase: sl.get<DeleteSellUseCase>(),
            businessRepository: sl.get<BusinessRepository>(),
            getPaymentAccountsByTypeUseCase:
                sl.get<GetPaymentAccountsByTypeUseCase>(),
            getFinalSellsUseCase: sl.get<GetFinalSellsUseCase>(),
          ),
        ),
        BlocProvider(
          create: (context) => CashierSessionCubit(),
        ),
      ],
      child: Builder(builder: (context) {
        return MultiBlocListener(
          listeners: [
            BlocListener<AuthCubit, AuthState>(
              listener: (context, authState) {
                if (authState is Unauthenticated) {
                  // Hide offline POS when logged out
                  // Don't navigate away - let webview handle login page
                  if (mounted) {
                    context
                        .read<PosOnlineBloc>()
                        .add(const PosOnlineHideOffline());
                  }
                }
              },
            ),
            BlocListener<CashierSessionCubit, CashierSessionState>(
              listenWhen: (pre, current) =>
                  pre.checkOutSuccess != current.checkOutSuccess,
              listener: (context, sessionState) {
                if (sessionState.checkOutSuccess) {
                  webViewController!.evaluateJavascript(source: _logoutScript);
                }
              },
            ),
          ],
          child: BlocConsumer<PosOnlineBloc, PosOnlineState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.errorMessage != current.errorMessage ||
                previous.successMessage != current.successMessage ||
                previous.showLogoutDialog != current.showLogoutDialog ||
                previous.showSyncDialog != current.showSyncDialog,
            listener: (context, state) {
              final l10n = AppLocalizations.of(context);

              if (state.status == PosOnlineStatus.error &&
                  state.errorMessage != null &&
                  mounted) {
                ToastManager.showError(context, state.errorMessage!);
              }

              if (state.status == PosOnlineStatus.success &&
                  state.successMessage != null &&
                  mounted) {
                final translatedMessage = l10n.translate(state.successMessage!);

                // If logout was successful, send script to webview
                if (state.successMessage == LocaleKeys.loggedOutSuccessfully &&
                    webViewController != null) {
                  webViewController!.evaluateJavascript(source: _logoutScript);
                }

                ToastManager.showSuccess(context, translatedMessage);
              }

              if (state.showLogoutDialog && mounted) {
                _showLogoutDialog(context, state.unsyncedSellsCount);
              }

              // Show sync dialog when syncing starts
              if (state.showSyncDialog && !_syncDialogShowing && mounted) {
                _showSyncDialog(context, state);
                _syncDialogShowing = true;
              } else if (!state.showSyncDialog &&
                  _syncDialogShowing &&
                  mounted) {
                // Close sync dialog when sync completes - only if we actually showed it
                _syncDialogShowing = false;
                if (Navigator.of(context, rootNavigator: true).canPop()) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              }
            },
            builder: (context, state) {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                body: SafeArea(
                  child: Stack(
                    children: [
                      ExcludeFocus(
                        excluding: false,
                        child: InAppWebView(
                          key: _webViewKey,
                          webViewEnvironment: _webViewEnvironment,
                          initialUrlRequest: URLRequest(
                            url: WebUri(_appConfig.webUrl),
                            headers: _requiredHeaders,
                          ),
                          gestureRecognizers: {}..addAll([
                              Factory<VerticalDragGestureRecognizer>(
                                () => VerticalDragGestureRecognizer(),
                              ),
                              Factory<HorizontalDragGestureRecognizer>(
                                () => HorizontalDragGestureRecognizer(),
                              ),
                            ]),
                          onLoadStop: (controller, url) async {
                            // Listen to URL changes
                            final urlString = url.toString();

                            // Check authentication on first load only
                            if (_isFirstLoad) {
                              _isFirstLoad = false;
                              _posOnlineBloc
                                  .add(const PosOnlineCheckAuthentication());
                            }

                            // Only logout if URL is login page AND user is authenticated
                            // Don't logout during login process (when authCompleted is being called)
                            if (urlString.contains('/login')) {
                              final authCubit = context.read<AuthCubit>();
                              final authState = authCubit.state;

                              // ROOT CAUSE FIX: Don't logout if:
                              // 1. AuthCubit is in AuthLoading state (login in progress)
                              // 2. Flag _isLoggingIn is true (authCompleted handler was called)
                              // 3. User is not authenticated (no need to logout)
                              final isLoginInProgress =
                                  authState is AuthLoading || _isLoggingIn;
                              final isAuthenticated = authCubit.isAuthenticated;

                              // Only logout if user is authenticated AND login is NOT in progress
                              if (isAuthenticated && !isLoginInProgress) {
                                Logger.logI(
                                    '🔄 [PosOnlinePage] URL changed to /login and user is authenticated - triggering logout');
                                // URL changed to login page - logout
                                _posOnlineBloc
                                    .add(const PosOnlineUrlChangedToLogin());
                              } else {
                                Logger.logI(
                                    'ℹ️ [PosOnlinePage] URL changed to /login but skipping logout - isLoginInProgress: $isLoginInProgress, isAuthenticated: $isAuthenticated');
                              }
                            }

                            await controller.evaluateJavascript(
                                source: _postAppReadySource);
                          },
                          onWebViewCreated: (controller) async {
                            webViewController = controller;

                            controller.addJavaScriptHandler(
                                handlerName: 'getCashierLogin',
                                callback: (args) async {
                                  try {
                                    // Parse data from webview
                                    // Format: {userId: number, amount: number, startTime: string, locationId?: number}
                                    final data = args[0] as Map<String, dynamic>;

                                    final userId =
                                        (data['userId'] as num?)?.toInt();
                                    final amount = double.tryParse(data['amount']
                                        .toString()
                                        .replaceAll(',', ''));
                                    final startTimeStr =
                                        data['startTime'] as String?;
                                    final locationId =
                                        (data['locationId'] as num?)?.toInt();

                                    if (userId == null ||
                                        amount == null ||
                                        startTimeStr == null) {
                                      if (mounted) {
                                        debugPrint(
                                            'Invalid cashier login data: $data');
                                      }
                                      return 'error: invalid_data';
                                    }

                                    // Parse startTime (format: "YYYY-MM-DD HH:mm:ss")
                                    final startTime =
                                        DateTime.tryParse(startTimeStr);
                                    if (startTime == null) {
                                      if (mounted) {
                                        debugPrint(
                                            'Invalid startTime format: $startTimeStr');
                                      }
                                      return 'error: invalid_time';
                                    }

                                    // LocationId should be provided from webview
                                    // If not provided, we cannot proceed
                                    if (locationId == null) {
                                      if (mounted) {
                                        debugPrint(
                                            'LocationId is required for cashier login');
                                      }
                                      return 'error: location_required';
                                    }

                                    // Save session locally (marked as synced since it's from online mode)
                                    final cashierSessionRepository =
                                        sl.get<CashierSessionRepository>();
                                    final result = await cashierSessionRepository
                                        .saveSessionLocally(
                                      userId: userId,
                                      locationId: locationId,
                                      openingAmount: amount,
                                      startTime: startTime,
                                      isSynced:
                                          true, // Already synced from webview
                                    );

                                    result.fold(
                                      onSuccess: (_) {
                                        if (mounted) {
                                          Logger.logI(
                                              'Cashier session cached successfully: userId=$userId, locationId=$locationId, amount=$amount');
                                        }
                                      },
                                      onError: (failure) {
                                        if (mounted) {
                                          Logger.logE(
                                              'Failed to cache cashier session: ${failure.message}');
                                        }
                                      },
                                    );

                                    return 'success';
                                  } catch (e) {
                                    if (mounted) {
                                      Logger.logE(
                                          'Error handling getCashierLogin: $e');
                                    }
                                    return 'error: ${e.toString()}';
                                  }
                                });

                            // Handle authentication completed
                            controller.addJavaScriptHandler(
                              handlerName: 'authCompleted',
                              callback: (args) async {
                                try {
                                  // Set flag to prevent logout during login
                                  _isLoggingIn = true;

                                  if (_windowsDeviceInfo != null) {
                                    final String deviceId = _windowsDeviceInfo!
                                        .deviceId
                                        .replaceAll('{', '')
                                        .replaceAll('}', '');
                                    controller.evaluateJavascript(
                                      source: _postHardWareId(deviceId),
                                    );
                                  }
                                  String accessToken = args[0][0];
                                  String userInfoJson = args[0][1];

                                  Map<String, dynamic> userMap =
                                      jsonDecode(userInfoJson);

                                  // Dispatch event to bloc
                                  context.read<PosOnlineBloc>().add(
                                        PosOnlineAuthCompleted(
                                          accessToken: accessToken,
                                          userInfo: userMap,
                                        ),
                                      );

                                  // Reset flag after a delay to allow login to complete
                                  Future.delayed(const Duration(seconds: 2), () {
                                    _isLoggingIn = false;
                                  });
                                } catch (e) {
                                  _isLoggingIn = false; // Reset flag on error
                                  if (mounted) {
                                    final l10n = AppLocalizations.of(context);
                                    ToastManager.showError(
                                      context,
                                      '${l10n.translate(LocaleKeys.error)}: $e',
                                    );
                                  }
                                }
                                return 'Receive';
                              },
                            );

                            // Handle logout from webview
                            controller.addJavaScriptHandler(
                              handlerName: 'logout',
                              callback: (args) async {
                                try {
                                  // Dispatch event to bloc
                                  context.read<PosOnlineBloc>().add(
                                        const PosOnlineLogoutFromWebview(),
                                      );
                                } catch (e) {
                                  if (mounted) {
                                    final l10n = AppLocalizations.of(context);
                                    ToastManager.showError(
                                      context,
                                      '${l10n.translate(LocaleKeys.error)}: $e',
                                    );
                                  }
                                }
                                return 'Receive';
                              },
                            );

                            controller.addJavaScriptHandler(
                              handlerName: 'customerDisplayOpened',
                              callback: (arguments) async {
                                try {
                                  if (_customerWindowController == null) {
                                    String href = arguments[0][0];
                                    _customerWindowController =
                                        await WindowManagerUtils.createNewWindow(
                                            WindowArguments(
                                      type: WindowType.onlineCustomer,
                                      params: {'href': href},
                                    ));
                                  } else {
                                    _customerWindowController!.show();
                                    _customerWindowController!.focus();
                                  }
                                } catch (e) {
                                  Logger.logE('customerDisplayOpened error', e);
                                }
                                return 'success';
                              },
                            );
                          },
                          onReceivedError: (controller, request, error) {
                            if (_offlineWebviewShown) return;
                            final code = error.type.toNativeValue();
                            if (code == 11) {
                              _offlineWebviewShown = true;
                              controller.loadData(
                                data: offlineHtml,
                                mimeType: 'text/html',
                                encoding: 'utf-8',
                                baseUrl: WebUri('about:blank'),
                              );
                            }
                          },
                        ),
                      ),
                      // POS Offline Screen (stacked on top when network disconnects)
                      if (state.showOfflinePos)
                        // if (true)
                        Positioned.fill(
                          child: const PosPage(),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  /// Show sync dialog
  void _showSyncDialog(BuildContext context, PosOnlineState state) {
    final l10n = AppLocalizations.of(context);
    final message = state.unsyncedSellsCount > 0
        ? l10n.translateWithArgs(LocaleKeys.syncingUnsyncedSales, {
            'count': state.unsyncedSellsCount,
          })
        : l10n.translate(LocaleKeys.syncingSystemData);

    DialogProvider.showLoadingDialog(
      context,
      message: message,
      barrierDismissible: false,
    );
  }

  /// Show logout dialog with unsynced sells
  void _showLogoutDialog(BuildContext context, int unsyncedCount) {
    final l10n = AppLocalizations.of(context);
    final theme = AppThemes.light;
    DialogProvider.showAppDialog(
      context,
      titleText: l10n.translate(LocaleKeys.pendingSynchronization),
      messageText: l10n.translateWithArgs(LocaleKeys.unsyncedSalesCount, {
        'count': unsyncedCount,
      }),
      actions: [
        BaseDialogAction(
          text: l10n.translate(LocaleKeys.sync),
          isPrimary: true,
          color: theme.primaryColor,
          onPressed: () {
            Navigator.pop(context);
            context.read<PosOnlineBloc>().add(
                  const PosOnlineLogoutWithSync(),
                );
          },
        ),
        BaseDialogAction(
          text: l10n.translate(LocaleKeys.cancel),
          isPrimary: false,
          color: Colors.grey,
          onPressed: () {
            Navigator.pop(context);
            context.read<PosOnlineBloc>().add(
                  const PosOnlineCancelLogout(),
                );
          },
        ),
      ],
    );
  }

  @override
  void update(bool newState) {
    if (!newState &&
        mounted &&
        !_posOnlineBloc.state.showOfflinePos &&
        context.authCubit.isAuthenticated &&
        !_popupOfflineIsShowed) {
      _popupOfflineIsShowed = true;
      final l10n = AppLocalizations.of(context);
      DialogProvider.showConfirmDialog(context,
          confirmColor: AppThemes.light.primaryColor,
          barrierDismissible: false,
          message: l10n.translate(LocaleKeys.networkConnectionIssue),
          onConfirm: () {
        _popupOfflineIsShowed = false;
        _posOnlineBloc.add(const PosOnlineShowOffline());
      }, onCancel: () {
        _popupOfflineIsShowed = false;
      });
    }

    if (_offlineWebviewShown) {
      _offlineWebviewShown = false;
      webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri(_appConfig.webUrl),
          headers: _requiredHeaders,
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    Logger.logI('didChangeAppLifecycleState, $state');
  }
}
