import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class VNCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {

    // Nếu text rỗng thì trả về giá trị rỗng
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanText.isEmpty) {
      return const TextEditingValue();
    }

    double value = double.parse(cleanText);

    final formatter = NumberFormat.decimalPattern('vi_VN');
    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}