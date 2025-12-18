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

  void _addFocusListener(){
    if(!mounted) return;
    final currentFocus = FocusManager.instance.primaryFocus;

    void requestFocus(){
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;

        _focusNode.requestFocus();
      });
    }
    bool isEditableText = false;

    if (currentFocus != null) {
      final widget = currentFocus.context?.widget;
      if (widget is Focus && widget.debugLabel == 'EditableText') {
        isEditableText = true;
      }
    }

    if (!isEditableText) {
      requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    FocusManager.instance.addListener(_addFocusListener);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_addFocusListener);
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
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: _handleKey,
        autofocus: false,
        child: widget.child,
      ),
    );
  }
}
