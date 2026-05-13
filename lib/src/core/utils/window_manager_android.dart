import 'dart:async';

import 'package:flutter_presentation_display/flutter_presentation_display.dart';

import 'window_manager_abstract.dart';

/// Android implementation of WindowManagerAbstract using flutter_presentation_display
class WindowManagerAndroid implements WindowManagerAbstract {
  final FlutterPresentationDisplay _display = FlutterPresentationDisplay();
  int? _currentDisplayId;
  WindowType? _currentWindowType;
  StreamSubscription? _displayChangeSubscription;
  final _windowStatusController = StreamController<WindowStatus>.broadcast();
  Function(Map<String, dynamic>)? _cartUpdateCallback;

  WindowManagerAndroid() {
    _setupDisplayListener();
  }

  void _setupDisplayListener() {
    _displayChangeSubscription = _display.connectedDisplaysChangedStream.listen((displayId) {
      // Handle display connection changes
      if (displayId == null) {
        // Display disconnected
        _currentDisplayId = null;
        _currentWindowType = null;
        _windowStatusController.add(WindowStatus(isOpen: false));
      } else {
        // Display connected - update status if we have an active window
        if (_currentDisplayId != null) {
          _windowStatusController.add(WindowStatus(
            isOpen: true,
            type: _currentWindowType,
          ));
        }
      }
    });

    // Listen for data from presentation display
    _display.listenDataFromPresentationDisplay((data) {
      // Handle data from customer window
      if (data is Map<String, dynamic> && _cartUpdateCallback != null) {
        _cartUpdateCallback!(data);
      }
    });
  }

  @override
  Future<void> openCustomerWindow({
    required WindowType type,
    Map<String, dynamic>? params,
  }) async {
    try {
      // Get available displays
      final displays = await _display.getDisplays();

      if (displays == null || displays.isEmpty) {
        throw Exception('No displays available');
      }

      // Use first secondary display (index 1) if available, otherwise look for non-zero displayId
      // For POS devices like SUNMI T2s, secondary display is usually at index 1
      int? displayId;
      if (displays.length > 1) {
        displayId = displays[1].displayId;
      }

      // Fallback: search for any display that is not ID 0
      displayId ??= displays.firstWhere(
        (d) => d.displayId != 0,
        orElse: () => displays[0],
      ).displayId;

      // Ensure we have a valid displayId (default to 1 if null or 0 as last resort, but 0 often fails)
      displayId ??= 1;

      // Determine entry point name based on type
      // On Android, routerName must match a top-level function marked with @pragma('vm:entry-point')
      final routerName = type == WindowType.offlineCustomer
          ? 'offlineCustomerMain'
          : 'onlineCustomerMain';

      // Show secondary display
      final result = await _display.showSecondaryDisplay(
        displayId: displayId,
        routerName: 'secondaryDisplayMain',
      );

      if (result == true) {
        _currentDisplayId = displayId;
        _currentWindowType = type;
        _windowStatusController.add(WindowStatus(
          isOpen: true,
          type: type,
        ));

        // Send initial data to presentation display if params provided
        if (params != null && params.isNotEmpty) {
          // Wait a bit for the secondary engine to start and listen
          await Future.delayed(const Duration(milliseconds: 1000));
          await _display.transferDataToPresentation(params);
        }
      } else {
        throw Exception('Failed to show secondary display');
      }
    } catch (e) {
      _currentDisplayId = null;
      _currentWindowType = null;
      _windowStatusController.add(WindowStatus(isOpen: false));
      rethrow;
    }
  }

  @override
  Future<void> closeCustomerWindow() async {
    if (_currentDisplayId != null) {
      try {
        await _display.hideSecondaryDisplay(displayId: _currentDisplayId!);
      } catch (e) {
        // Ignore errors
      }
      _currentDisplayId = null;
      _currentWindowType = null;
      _windowStatusController.add(WindowStatus(isOpen: false));
    }
  }

  @override
  Future<void> showCustomerWindow() async {
    // TODO: Implement when flutter_presentation_display package is available
    if (_currentDisplayId != null && _currentWindowType != null) {
      // Reopen if needed
      await openCustomerWindow(type: _currentWindowType!);
    }
  }

  @override
  Future<void> hideCustomerWindow() async {
    await closeCustomerWindow();
  }

  @override
  Future<bool> isCustomerWindowOpen() async {
    return _currentDisplayId != null;
  }

  @override
  Stream<WindowStatus> get windowStatusStream => _windowStatusController.stream;

  /// Transfer data to customer window (presentation display)
  Future<void> transferDataToCustomer(Map<String, dynamic> data) async {
    if (_currentDisplayId != null) {
      try {
        await _display.transferDataToPresentation(data);
      } catch (e) {
        // Handle error silently or log
      }
    }
  }

  @override
  Future<void> syncCartData(Map<String, dynamic> cartData) async {
    if (_currentDisplayId == null) return;

    try {
      await _display.transferDataToPresentation(cartData);
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void listenToCartUpdates(Function(Map<String, dynamic>) onUpdate) {
    _cartUpdateCallback = onUpdate;
    // Listener is already set up in _setupDisplayListener
  }

  @override
  void unregisterCartListener() {
    _cartUpdateCallback = null;
  }

  @override
  void dispose() {
    _displayChangeSubscription?.cancel();
    unregisterCartListener();
    _windowStatusController.close();
  }
}
