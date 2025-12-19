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
    if (event is! KeyDownEvent) return false;

    // Check if focus is on a text input field
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode != null) {
      final widget = focusNode.context?.widget;
      // More robust check: if focus is on any text input, don't intercept
      // Check for TextField, TextFormField, or any widget with EditableText
      if (widget != null) {
        final widgetType = widget.runtimeType.toString();
        if (widgetType.contains('TextField') || 
            widgetType.contains('TextFormField') ||
            widgetType.contains('EditableText')) {
          return false; // Let the text field handle it
        }
      }
    }

    final char = event.character;
    if (char == null || char.isEmpty) return false;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_buffer.isNotEmpty) {
        onBarcodeScanned(_buffer);
      }
      _buffer = '';
      return true; // handled
    }

    _buffer += char;
    return true; // handled
  }
}
