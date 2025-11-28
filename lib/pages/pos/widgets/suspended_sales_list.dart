import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/sell_database.dart';
import 'package:pos_final/models/system.dart';

import '../../../helpers/other_helpers.dart';
import '../../../models/database.dart';

class SuspendedSalesList extends StatefulWidget {
  final Function(Map<String, dynamic>) onSaleSelected;

  const SuspendedSalesList({
    super.key,
    required this.onSaleSelected,
  });

  @override
  SuspendedSalesListState createState() => SuspendedSalesListState();
}

class SuspendedSalesListState extends State<SuspendedSalesList> {
  List<Map<String, dynamic>> suspendedSales = [];
  bool isLoading = true;
  String symbol = '';
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    _fetchSuspendedSales();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final value = await Helper().getFormattedBusinessDetails();
    if (mounted) {
      setState(() {
        symbol = value['symbol'] != null ? value['symbol'] + ' ' : '';
      });
    }
  }

  Future<void> _fetchSuspendedSales() async {
    setState(() {
      isLoading = true;
    });
    try {
      final db = await DbProvider.db.database; // Use db.database to get Database instance
      final sales = await db.query(
        'sell',
        where: 'is_suspend = ?',
        whereArgs: [1],
        orderBy: 'transaction_date DESC',
      );
      if (mounted) {
        setState(() {
          suspendedSales = sales.map((sale) => Map<String, dynamic>.from(sale)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('failed_to_load_suspended_sales')),
          ),
        );
      }
    }
  }

  Future<void> _deleteSuspendedSale(int sellId) async {
    try {
      final db = await DbProvider.db.database; // Use db.database to get Database instance
      await db.delete('sell', where: 'id = ?', whereArgs: [sellId]);
      await db.delete('sell_lines', where: 'sell_id = ?', whereArgs: [sellId]);
      await db.delete('sell_payments', where: 'sell_id = ?', whereArgs: [sellId]);
      if (mounted) {
        setState(() {
          suspendedSales.removeWhere((sale) => sale['id'] == sellId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('suspended_sale_deleted')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('failed_to_delete_suspended_sale')),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(int sellId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm')),
        content: Text(AppLocalizations.of(context).translate('are_you_sure_delete')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('no')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteSuspendedSale(sellId);
            },
            child: Text(AppLocalizations.of(context).translate('yes')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);

    return AlertDialog(
      title: Text(
        AppLocalizations.of(context).translate('suspended_sales'),
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: (MySize.size18 ?? 18.0).toDouble(),
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : suspendedSales.isEmpty
            ? Center(
          child: Text(
            AppLocalizations.of(context).translate('no_suspended_sales'),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: (MySize.size16 ?? 16.0).toDouble(),
              color: themeData.colorScheme.onSurface.withAlpha(150),
            ),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          itemCount: suspendedSales.length,
          itemBuilder: (context, index) {
            final sale = suspendedSales[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: (MySize.size4 ?? 4.0).toDouble()),
              child: ListTile(
                title: Text(
                  sale['invoice_no']?.toString() ?? 'N/A',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size16 ?? 16.0).toDouble(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${AppLocalizations.of(context).translate('date')}: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(sale['transaction_date']))}\n'
                      '${AppLocalizations.of(context).translate('total')}: $symbol${Helper().formatCurrency(sale['invoice_amount'] ?? 0.0)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.play_arrow,
                        color: themeData.colorScheme.primary,
                        size: (MySize.size24 ?? 24.0).toDouble(),
                      ),
                      onPressed: () async {
                        final sellLines = await SellDatabase().getSellLines(sale['id']);
                        widget.onSaleSelected({
                          'sale': sale,
                          'sell_lines': sellLines,
                        });
                        Navigator.of(context).pop();
                      },
                      tooltip: AppLocalizations.of(context).translate('resume_sale'),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: (MySize.size24 ?? 24.0).toDouble(),
                      ),
                      onPressed: () => _showDeleteConfirmationDialog(sale['id']),
                      tooltip: AppLocalizations.of(context).translate('delete'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            AppLocalizations.of(context).translate('close'),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: (MySize.size14 ?? 14.0).toDouble(),
              color: themeData.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}