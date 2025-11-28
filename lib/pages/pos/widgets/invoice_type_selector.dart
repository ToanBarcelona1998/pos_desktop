import 'package:flutter/material.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';

class InvoiceTypeSelector extends StatefulWidget {
  final Function(String?, bool?, bool?) onInvoiceTypeSelected;
  final String? selectedInvoiceType;
  final bool? isQuotation;
  final bool? isSuspend;

  const InvoiceTypeSelector({
    super.key,
    required this.onInvoiceTypeSelected,
    this.selectedInvoiceType,
    this.isQuotation,
    this.isSuspend,
  });

  @override
  InvoiceTypeSelectorState createState() => InvoiceTypeSelectorState();
}

class InvoiceTypeSelectorState extends State<InvoiceTypeSelector> {
  String? selectedInvoiceType;
  bool? isQuotation;
  bool? isSuspend;
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    selectedInvoiceType = widget.selectedInvoiceType ?? 'final';
    isQuotation = widget.isQuotation ?? false;
    isSuspend = widget.isSuspend ?? false;
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);

    return Container(
      padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((MySize.size12 ?? 12.0).toDouble()),
        boxShadow: [
          BoxShadow(
            color: themeData.cardTheme.shadowColor?.withAlpha(48) ?? Colors.grey.withAlpha(48),
            blurRadius: (MySize.size8 ?? 8.0).toDouble(),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long,
            size: (MySize.size24 ?? 24.0).toDouble(),
            color: themeData.colorScheme.primary,
          ),
          SizedBox(width: (MySize.size12 ?? 12.0).toDouble()),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedInvoiceType,
                hint: Text(
                  AppLocalizations.of(context).translate('select_invoice_type'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size16 ?? 16.0).toDouble(),
                    color: themeData.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
                items: [
                  {'value': 'final', 'label': 'final'},
                  {'value': 'draft', 'label': 'draft'},
                  {'value': 'quotation', 'label': 'quotation'},
                  {'value': 'suspend', 'label': 'suspend'},
                ].map<DropdownMenuItem<String>>((Map item) {
                  return DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(
                      AppLocalizations.of(context).translate(item['label']),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: (MySize.size16 ?? 16.0).toDouble(),
                        color: themeData.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedInvoiceType = newValue;
                    isQuotation = newValue == 'quotation';
                    isSuspend = newValue == 'suspend';
                    widget.onInvoiceTypeSelected(newValue, isQuotation, isSuspend);
                  });
                },
                dropdownColor: Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: themeData.colorScheme.primary,
                  size: (MySize.size24 ?? 24.0).toDouble(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}