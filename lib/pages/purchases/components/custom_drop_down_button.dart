import 'package:flutter/material.dart';

class CustomDropDownButton<T> extends StatelessWidget {
  const CustomDropDownButton(
      {super.key,
      required this.titleText,
      this.isRequiredFill = false,
      required this.items,
      this.onChanged,
      this.validator});

  final String titleText;
  final bool isRequiredFill;
  final List<DropdownMenuItem<T>>? items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
            text: TextSpan(
                text: titleText,
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: const Color(0xFF202532)),
                children: [
              if (isRequiredFill)
                TextSpan(
                    text: " *",
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        color: Colors.red))
            ])),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
            items: items,
            validator: validator,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(15),
            hint: Text(titleText),
            isExpanded: true,
            onChanged: onChanged)
      ],
    );
  }
}
