import 'package:flutter/material.dart';

class QuantityInput extends StatefulWidget {
  final int initialQuantity;
  final ValueChanged<int>? onChanged;

  const QuantityInput({
    super.key,
    required this.initialQuantity,
    this.onChanged,
  });

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput> {
  late TextEditingController _controller;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
    _controller = TextEditingController(text: _quantity.toString());
  }

  void _updateQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(0, double.infinity).toInt();
      _controller.text = _quantity.toString();
      if (widget.onChanged != null) {
        widget.onChanged!(_quantity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          color: Colors.red,
          onPressed: () => _updateQuantity(-1),
          splashRadius: 20,
        ),
        SizedBox(
          width: 60,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
            ),
            onChanged: (text) {
              final newQuantity = int.tryParse(text) ?? 0;
              if (newQuantity != _quantity) {
                _quantity = newQuantity;
                if (widget.onChanged != null) {
                  widget.onChanged!(_quantity);
                }
              }
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          color: Colors.green,
          onPressed: () => _updateQuantity(1),
          splashRadius: 20,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
