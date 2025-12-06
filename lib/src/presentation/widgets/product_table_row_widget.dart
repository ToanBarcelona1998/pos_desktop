import 'package:flutter/material.dart';
import 'package:pos_final/src/presentation/widgets/quantity_input_widget.dart';

class ProductTableRow extends StatelessWidget {
  const ProductTableRow({super.key});

  @override
  Widget build(BuildContext context) {
    const TextStyle headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.black54,
      fontSize: 14,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            children: [
              const Expanded(
                flex: 3,
                child: Text('Sản phẩm', style: headerStyle),
              ),
              Expanded(
                child: Text('Số lượng',
                    style: headerStyle, textAlign: TextAlign.center),
              ),
              Expanded(
                child: Text('Giá sau thuế',
                    style: headerStyle, textAlign: TextAlign.right),
              ),
              Expanded(
                child: Text('Thành tiền',
                    style: headerStyle, textAlign: TextAlign.right),
              ),
              const SizedBox(
                width: 40,
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                flex: 3,
                child: Text(
                  'Laptop Gaming Acer Nitro 5 (AN515-58)',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              QuantityInput(
                initialQuantity: 2,
                onChanged: (newQty) {},
              ),
              Text(
                '25.000.000',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '50.000.000',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.redAccent,
                onPressed: () {},
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
