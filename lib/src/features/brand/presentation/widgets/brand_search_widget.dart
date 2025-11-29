import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/brand_list_cubit.dart';

/// Widget for searching brands
class BrandSearchWidget extends StatefulWidget {
  const BrandSearchWidget({super.key});

  @override
  State<BrandSearchWidget> createState() => _BrandSearchWidgetState();
}

class _BrandSearchWidgetState extends State<BrandSearchWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search brands...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    context.read<BrandListCubit>().searchBrands('');
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onChanged: (value) {
          context.read<BrandListCubit>().searchBrands(value);
          setState(() {});
        },
      ),
    );
  }
}

