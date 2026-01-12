import 'dart:async';

import 'package:desktop_multi_window/desktop_multi_window.dart';

import 'window_manager_abstract.dart';
import 'window_manager_utils.dart' as utils;

/// Desktop implementation of WindowManagerAbstract
class WindowManagerDesktop implements WindowManagerAbstract {
  WindowController? _customerWindowController;
  final _windowStatusController = StreamController<WindowStatus>.broadcast();
  StreamSubscription? _windowChangeSubscription;
  WindowMethodChannel? _methodChannel;
  Function(Map<String, dynamic>)? _cartUpdateCallback;

  WindowManagerDesktop() {
    _setupWindowListener();
  }

  void _setupWindowListener() {
    // Listen to window changes
    // Note: desktop_multi_window doesn't provide direct window change stream
    // This is a placeholder - actual implementation may need to poll or use
    // existing WindowController methods
  }

  @override
  Future<void> openCustomerWindow({
    required WindowType type,
    Map<String, dynamic>? params,
  }) async {
    try {
      // If window already exists, show and focus it
      if (_customerWindowController != null) {
        await _customerWindowController!.show();
        await _customerWindowController!.focus();
        return;
      }

      // Create window arguments
      final windowArgs = utils.WindowArguments(
        type: type == WindowType.offlineCustomer
            ? utils.WindowType.offlineCustomer
            : utils.WindowType.onlineCustomer,
        params: params ?? {},
      );

      // Create new window
      _customerWindowController = await utils.WindowManagerUtils.createNewWindow(windowArgs);

      _windowStatusController.add(WindowStatus(
        isOpen: true,
        type: type,
      ));
    } catch (e) {
      _windowStatusController.add(WindowStatus(isOpen: false));
      rethrow;
    }
  }

  @override
  Future<void> closeCustomerWindow() async {
    if (_customerWindowController != null) {
      try {
        await _customerWindowController!.close();
      } catch (e) {
        // Ignore errors when closing
      }
      _customerWindowController = null;
      _windowStatusController.add(WindowStatus(isOpen: false));
    }
  }

  @override
  Future<void> showCustomerWindow() async {
    if (_customerWindowController != null) {
      await _customerWindowController!.show();
      await _customerWindowController!.focus();
    }
  }

  @override
  Future<void> hideCustomerWindow() async {
    if (_customerWindowController != null) {
      // Desktop doesn't have explicit hide, but we can minimize
      // For now, we'll keep it visible but this can be extended
    }
  }

  @override
  Future<bool> isCustomerWindowOpen() async {
    if (_customerWindowController == null) return false;

    try {
      final windows = await WindowController.getAll();
      return windows.map((e) => e.windowId).contains(_customerWindowController!.windowId);
    } catch (e) {
      return false;
    }
  }

  @override
  Stream<WindowStatus> get windowStatusStream => _windowStatusController.stream;

  @override
  Future<void> syncCartData(Map<String, dynamic> cartData) async {
    if (_customerWindowController == null) return;

    try {
      _methodChannel ??= WindowMethodChannel(
        'com.oman.offline_customer_channel',
        mode: ChannelMode.unidirectional,
      );

      await _methodChannel!.invokeMethod('update_cart', {
        'data': cartData,
      });
    } catch (e) {
      // Window might be closed, ignore error
    }
  }

  @override
  void listenToCartUpdates(Function(Map<String, dynamic>) onUpdate) {
    _cartUpdateCallback = onUpdate;

    try {
      _methodChannel ??= WindowMethodChannel(
        'com.oman.offline_customer_channel',
        mode: ChannelMode.unidirectional,
      );

      _methodChannel!.setMethodCallHandler((call) async {
        if (call.method == 'update_cart') {
          try {
            final data = Map<String, dynamic>.from(call.arguments);
            if (data['data'] != null) {
              final cartData = Map<String, dynamic>.from(data['data']);
              onUpdate(cartData);
            }
          } catch (e) {
            // Ignore parse errors
          }
        }
      });
    } catch (e) {
      // Ignore setup errors
    }
  }

  @override
  void unregisterCartListener() {
    _cartUpdateCallback = null;
    try {
      _methodChannel?.setMethodCallHandler(null);
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _windowChangeSubscription?.cancel();
    unregisterCartListener();
    _windowStatusController.close();
  }

  /// Get the current window controller (for desktop-specific operations)
  WindowController? get windowController => _customerWindowController;
}
