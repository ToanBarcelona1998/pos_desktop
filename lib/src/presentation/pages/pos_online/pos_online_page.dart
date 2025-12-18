import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pos_final/app_config/app_config.dart';
import 'package:pos_final/app_config/di.dart';
import 'package:pos_final/src/application.dart';
import 'package:pos_final/src/application/application.dart';
import 'package:pos_final/src/core/core.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_observer.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_subject.dart';
import 'package:pos_final/src/presentation/widgets/dialog/dialog_provider.dart';
import 'package:pos_final/src/presentation/widgets/dialog/base_dialog_widget.dart';
import 'package:data/data.dart';

import '../../presentation.dart';

class PosOnlinePage extends StatefulWidget {
  const PosOnlinePage({super.key});

  @override
  State<PosOnlinePage> createState() => _PosOnlinePageState();
}

class _PosOnlinePageState extends State<PosOnlinePage>
    implements NetworkStatusObserver {
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
    isInspectable: false,
    mediaPlaybackRequiresUserGesture: false,
    allowsInlineMediaPlayback: true,
    iframeAllow: "camera; microphone",
    iframeAllowFullscreen: true,
  );

  late PosOnlineBloc _posOnlineBloc;

  late NetworkStatusSubject _networkStatusSubject;

  bool _isFirstLoad = true;
  bool _syncDialogShowing = false;
  bool _popupOfflineIsShowed = false;

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
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is Unauthenticated) {
            // Hide offline POS when logged out
            // Don't navigate away - let webview handle login page
            if (mounted) {
              context.read<PosOnlineBloc>().add(const PosOnlineHideOffline());
            }
          }
        },
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
            } else if (!state.showSyncDialog && _syncDialogShowing && mounted) {
              // Close sync dialog when sync completes - only if we actually showed it
              _syncDialogShowing = false;
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            }
          },
          builder: (context, state) {
            return Scaffold(
              body: SafeArea(
                child: Stack(
                  children: [
                    InAppWebView(
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
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        ]),
                      onLoadStop: (controller, url) async {
                        // Listen to URL changes
                        final urlString = url.toString();
                        if (urlString.contains('/login')) {
                          // URL changed to login page - logout
                          _posOnlineBloc
                              .add(const PosOnlineUrlChangedToLogin());
                        } else {
                          // Check authentication on first load only
                          if (_isFirstLoad) {
                            _isFirstLoad = false;
                            _posOnlineBloc
                                .add(const PosOnlineCheckAuthentication());
                          }
                        }

                        await controller.evaluateJavascript(
                            source: _postAppReadySource);
                      },
                      onWebViewCreated: (controller) async {
                        webViewController = controller;

                        // Handle authentication completed
                        controller.addJavaScriptHandler(
                          handlerName: 'authCompleted',
                          callback: (args) async {
                            try {
                              if(_windowsDeviceInfo != null){
                                final String deviceId = _windowsDeviceInfo!.deviceId.replaceAll('{', '')
                                    .replaceAll('}', '');
                                controller.evaluateJavascript(
                                  source:
                                  _postHardWareId(deviceId),
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
                      },
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
      ),
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
          color: Colors.blue,
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
          barrierDismissible: false,
          message: l10n.translate(LocaleKeys.networkConnectionIssue),
          onConfirm: () {
        _popupOfflineIsShowed = false;
        _posOnlineBloc.add(const PosOnlineShowOffline());
      }, onCancel: () {
        _popupOfflineIsShowed = false;
      });
    }
  }
}
