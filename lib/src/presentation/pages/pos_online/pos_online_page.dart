import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pos_final/app_config/app_config.dart';
import 'package:pos_final/app_config/di.dart';
import 'package:pos_final/src/application/application.dart';
import 'package:pos_final/src/core/core.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_observer.dart';
import 'package:pos_final/src/core/observers/network_status/network_status_subject.dart';
import 'package:pos_final/src/presentation/pages/pos/pos_page.dart';
import 'package:pos_final/src/presentation/widgets/dialog/dialog_provider.dart';
import 'package:data/data.dart';

import 'pos_online_bloc.dart';
import 'pos_online_event.dart';
import 'pos_online_state.dart';

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

  late NetworkStatusSubject _networkStatusSubject;

  final AppConfig _appConfig = sl.get<AppConfig>();

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

  @override
  void initState() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider(
      create: (context) => PosOnlineBloc(
        authCubit: context.read<AuthCubit>(),
        syncService: sl.get<SystemSyncService>(),
        sellRepository: sl.get<SellRepository>(),
      )..add(const PosOnlineInitialize()),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is Unauthenticated) {
            // Hide offline POS when logged out
            context.read<PosOnlineBloc>().add(const PosOnlineHideOffline());
          }
        },
        child: BlocConsumer<PosOnlineBloc, PosOnlineState>(
          listenWhen: (previous, current) =>
              previous.failure != current.failure ||
              previous.successMessage != current.successMessage ||
              previous.showLogoutDialog != current.showLogoutDialog ||
              previous.isSyncing != current.isSyncing,
          listener: (context, state) {
            final l10n = AppLocalizations.of(context);

            if (state.failure != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.failure!.message),
                  backgroundColor: Colors.red,
                ),
              );
            }

            if (state.successMessage != null) {
              final translatedMessage = l10n.translate(state.successMessage!);
              
              // If logout was successful, send script to webview
              if (state.successMessage == 'logged_out_successfully' && webViewController != null) {
                webViewController!.evaluateJavascript(source: _logoutScript);
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(translatedMessage),
                  backgroundColor: Colors.green,
                ),
              );
            }

            if (state.showLogoutDialog) {
              _showLogoutDialog(context, state.unsyncedSellsCount);
            }

            // Show sync dialog when syncing starts
            if (state.isSyncing && !state.showLogoutDialog) {
              _showSyncDialog(context, state);
            } else if (!state.isSyncing && !state.showLogoutDialog) {
              // Close sync dialog when sync completes
              if (Navigator.of(context, rootNavigator: true).canPop()) {
                Navigator.of(context, rootNavigator: true).pop();
              }
            }
          },
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(l10n.translate(LocaleKeys.posSales)),
                ),
                centerTitle: true,
                leading: null,
                automaticallyImplyLeading: false,
                actions: [
                  // Only show sync and logout buttons when authenticated
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      if (authState is Authenticated) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sync button
                            IconButton(
                              icon: const Icon(Icons.sync),
                              tooltip: l10n.translate(LocaleKeys.syncData),
                              onPressed: () {
                                context.read<PosOnlineBloc>().add(
                                      const PosOnlineSync(),
                                    );
                              },
                            ),
                            // Logout button
                            IconButton(
                              icon: const Icon(Icons.logout),
                              tooltip: l10n.translate(LocaleKeys.logout),
                              onPressed: () {
                                context.read<PosOnlineBloc>().add(
                                      const PosOnlineLogout(),
                                    );
                              },
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: Stack(
                  children: [
                    InAppWebView(
                      initialUrlRequest: URLRequest(
                        url: WebUri(_appConfig.webUrl),
                        headers: _requiredHeaders,
                      ),
                      onLoadStop: (controller, url) async {
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
                              String accessToken = args[0][0];
                              String userInfoJson = args[0][1];

                              Map<String, dynamic> userMap = jsonDecode(userInfoJson);

                              // Dispatch event to bloc
                              context.read<PosOnlineBloc>().add(
                                    PosOnlineAuthCompleted(
                                      accessToken: accessToken,
                                      userInfo: userMap,
                                    ),
                                  );
                            } catch (e) {
                              print('Error handling auth from webview: $e');
                              if (mounted) {
                                final l10n = AppLocalizations.of(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${l10n.translate(LocaleKeys.error)}: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
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
                              print('Received logout message from webview');
                              // Dispatch event to bloc
                              context.read<PosOnlineBloc>().add(
                                    const PosOnlineLogoutFromWebview(),
                                  );
                            } catch (e) {
                              print('Error handling logout from webview: $e');
                              if (mounted) {
                                final l10n = AppLocalizations.of(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${l10n.translate(LocaleKeys.error)}: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
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
                      Positioned.fill(
                        child: Scaffold(
                          appBar: AppBar(
                            title: Text(l10n.translate(LocaleKeys.pos)),
                            leading: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () {
                                context.read<PosOnlineBloc>().add(
                                      const PosOnlineHideOffline(),
                                    );
                              },
                              tooltip: l10n.translate(LocaleKeys.back),
                            ),
                          ),
                          body: const PosPage(),
                        ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(
                state.unsyncedSellsCount > 0
                    ? l10n.translateWithArgs(LocaleKeys.syncingUnsyncedSales, {
                        'count': state.unsyncedSellsCount,
                      })
                    : l10n.translate(LocaleKeys.syncingSystemData),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show logout dialog with unsynced sells
  void _showLogoutDialog(BuildContext context, int unsyncedCount) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            l10n.translate(LocaleKeys.pendingSynchronization),
          ),
          content: Text(
            l10n.translateWithArgs(LocaleKeys.unsyncedSalesCount, {
              'count': unsyncedCount,
            }),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<PosOnlineBloc>().add(
                      const PosOnlineLogoutWithSync(),
                    );
              },
              child: Text(
                l10n.translate(LocaleKeys.syncAndLogout),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<PosOnlineBloc>().add(
                      const PosOnlineLogoutWithoutSync(),
                    );
              },
              child: Text(
                l10n.translate(LocaleKeys.logoutWithoutSync),
                style: const TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<PosOnlineBloc>().add(
                      const PosOnlineCancelLogout(),
                    );
              },
              child: Text(l10n.translate(LocaleKeys.cancel)),
            ),
          ],
        );
      },
    );
  }

  @override
  void update(bool newState) {
    if (!newState && mounted) {
      final l10n = AppLocalizations.of(context);
      DialogProvider.showConfirmDialog(
        context,
        message: l10n.translate(LocaleKeys.networkConnectionIssue),
        onConfirm: () {
          context.read<PosOnlineBloc>().add(const PosOnlineShowOffline());
        },
      );
    }
  }
}
