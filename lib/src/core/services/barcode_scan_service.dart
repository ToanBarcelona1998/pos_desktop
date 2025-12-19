import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class WindowActiveObserver with WidgetsBindingObserver {
  final ValueNotifier<bool> isActive = ValueNotifier(true);

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isActive.value = state == AppLifecycleState.resumed;
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

    final focusWidget =
        FocusManager.instance.primaryFocus?.context?.widget;

    if (focusWidget is Focus && focusWidget.debugLabel == 'EditableText') {
      return false;
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
