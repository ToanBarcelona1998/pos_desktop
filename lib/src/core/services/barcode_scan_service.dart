import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class WindowActiveObserver with WidgetsBindingObserver {
  final ValueNotifier<bool> isActive = ValueNotifier(true);

  void init() {
    WidgetsBinding.instance.addObserver(this);
    // On desktop, check initial state - assume active if app is running
    // This ensures scanner is enabled by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = WidgetsBinding.instance.lifecycleState;
      isActive.value = currentState == null ||
          currentState == AppLifecycleState.resumed ||
          currentState == AppLifecycleState.inactive;
    });
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On desktop, consider both resumed and inactive as "active" for barcode scanning
    // Inactive means window is still visible but not focused (which is fine for scanning)
    isActive.value = state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
  }
}

class BarcodeScannerService {
  BarcodeScannerService({
    required this.onBarcodeScanned,
  });

  final void Function(String barcode) onBarcodeScanned;

  String _buffer = '';
  bool _enabled = true;

  void start() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  void stop() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _buffer = '';
  }

  void setEnabled(bool value) {
    _enabled = value;
    if (!value) _buffer = '';
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_enabled) return false;
    // Check if focus is inside a text input field - do NOT consume keys in that case.
    // Previously used widget.debugLabel == 'EditableText' which is unreliable
    // (e.g. on Windows/desktop the focused widget hierarchy can differ).
    final focusNode = FocusManager.instance.primaryFocus;
    final context = focusNode?.context;
    if (context != null) {
      if (context.findAncestorWidgetOfExactType<TextField>() != null ||
          context.findAncestorWidgetOfExactType<TextFormField>() != null) {
        _buffer = '';
        return false; // Let the text field receive the key
      }
    }

    if(event is KeyDownEvent){
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_buffer.isNotEmpty) {
          onBarcodeScanned(_buffer);
        }
        _buffer = '';
        return true; // handled
      } else if (event.logicalKey.keyLabel.length == 1 &&
          event.logicalKey != LogicalKeyboardKey.space) {
        _buffer += event.logicalKey.keyLabel;
      }
      return true; // handled
    }

    return false;
  }
}
