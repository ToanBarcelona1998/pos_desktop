import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RawBarCodeListenerWidget extends StatefulWidget {
  final Widget child;
  final Function(String barcode) onBarcodeScanned;

  const RawBarCodeListenerWidget({
    required this.child,
    super.key,
    required this.onBarcodeScanned,
  });

  @override
  State<RawBarCodeListenerWidget> createState() =>
      _RawBarCodeListenerWidgetState();
}

class _RawBarCodeListenerWidgetState extends State<RawBarCodeListenerWidget> {
  String _barcode = '';

  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcode.isNotEmpty) {
          widget.onBarcodeScanned(_barcode);
        }
        _barcode = '';
      } else if (event.logicalKey.keyLabel.length == 1 &&
          event.logicalKey != LogicalKeyboardKey.space) {
        _barcode += event.logicalKey.keyLabel;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      autofocus: true,
      child: widget.child,
    );
  }
}
