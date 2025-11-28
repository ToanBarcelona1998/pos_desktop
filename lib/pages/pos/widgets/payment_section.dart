import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_final/config.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/sell.dart';
import 'package:pos_final/models/sell_database.dart';
import 'package:pos_final/models/system.dart';

class PaymentSection extends StatefulWidget {
  final double invoiceAmount;
  final int? branchId;
  final int? customerId;
  final List<dynamic> cartItems;
  final VoidCallback onPaymentCompleted;

  const PaymentSection({
    super.key,
    required this.invoiceAmount,
    this.branchId,
    this.customerId,
    required this.cartItems,
    required this.onPaymentCompleted,
  });

  @override
  PaymentSectionState createState() => PaymentSectionState();
}

class PaymentSectionState extends State<PaymentSection> {
  List<Map<String, dynamic>> paymentMethods = [];
  List<Map<String, dynamic>> paymentAccounts = [
    {'id': null, 'name': 'None'}
  ];
  List<Map<String, dynamic>> payments = [];
  List<TextEditingController> paymentAmountControllers = [];
  List<TextEditingController> paymentNoteControllers = [];
  double totalPaying = 0.0;
  double pendingAmount = 0.0;
  double changeReturn = 0.0;
  double advanceBalance = 0.0;
  String symbol = '';
  String invoiceType = 'Mobile';
  bool printInvoice = true;
  bool isLoading = false;
  final TextEditingController saleNoteController = TextEditingController();
  final TextEditingController staffNoteController = TextEditingController();
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    setState(() {
      isLoading = true;
    });
    await Helper().getFormattedBusinessDetails().then((value) {
      if (mounted) {
        setState(() {
          symbol = value['symbol'] != null ? value['symbol'] + ' ' : '';
        });
      }
    });
    await fetchPaymentMethods();
    await fetchPaymentAccounts();
    if (widget.customerId != null) {
      advanceBalance = await Helper().getAdvanceBalance(widget.customerId);
    }
    if (mounted) {
      setState(() {
        if (widget.invoiceAmount > 0) {
          payments.add({
            'amount': widget.invoiceAmount,
            'method': paymentMethods.isNotEmpty ? paymentMethods[0]['name'] : 'cash',
            'note': '',
            'account_id': paymentMethods.isNotEmpty ? paymentMethods[0]['account_id'] : null,
          });
          paymentAmountControllers.add(TextEditingController(text: widget.invoiceAmount.toStringAsFixed(2)));
          paymentNoteControllers.add(TextEditingController());
          calculateMultiPayment();
        }
        isLoading = false;
      });
    }
  }

  Future<void> fetchPaymentMethods() async {
    List methods = await System().get('payment_method', widget.branchId);
    if (mounted) {
      setState(() {
        paymentMethods.clear();
        for (var element in methods) {
          if (element['name'] != null) {
            paymentMethods.add({
              'name': element['name'] as String,
              'value': element['label']?.toString() ?? element['name'],
              'account_id': element['account_id'] != null
                  ? int.tryParse(element['account_id'].toString())
                  : null,
            });
          }
        }
      });
    }
  }

  Future<void> fetchPaymentAccounts() async {
    List accounts = await System().getPaymentAccounts();
    List methods = await System().get('payment_method', widget.branchId);
    if (mounted) {
      setState(() {
        paymentAccounts.clear();
        paymentAccounts.add({'id': null, 'name': 'None'});
        for (var element in accounts) {
          for (var method in methods) {
            if (method['account_id']?.toString() == element['id']?.toString()) {
              paymentAccounts.add({
                'id': element['id'] as int?,
                'name': element['name']?.toString() ?? '',
              });
              break;
            }
          }
        }
      });
    }
  }

  void calculateMultiPayment() {
    totalPaying = 0.0;
    for (int i = 0; i < payments.length; i++) {
      payments[i]['amount'] = double.tryParse(paymentAmountControllers[i].text) ?? 0.0;
      totalPaying += payments[i]['amount'];
    }
    double totalInvoice = widget.invoiceAmount; // Removed shipping charges
    double totalPayable = totalInvoice - advanceBalance.clamp(0.0, totalInvoice);
    if (totalPaying > totalPayable) {
      changeReturn = totalPaying - totalPayable;
      pendingAmount = 0.0;
    } else if (totalPayable > totalPaying) {
      pendingAmount = totalPayable - totalPaying;
      changeReturn = 0.0;
    } else {
      pendingAmount = 0.0;
      changeReturn = 0.0;
    }
    setState(() {});
  }

  Future<void> onSubmit() async {
    if (widget.cartItems.isEmpty || widget.customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart empty or no customer selected')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String transactionDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      Map<String, dynamic> sell = await Sell().createSell(
        invoiceNo: "${Config.userId}_${DateFormat('yMdHm').format(DateTime.now())}",
        transactionDate: transactionDate,
        changeReturn: changeReturn,
        contactId: widget.customerId,
        discountAmount: 0.0,
        discountType: 'fixed',
        invoiceAmount: widget.invoiceAmount,
        locId: widget.branchId,
        pending: pendingAmount,
        saleNote: saleNoteController.text,
        saleStatus: 'final',
        staffNote: staffNoteController.text,
        taxId: 0,
        isQuotation: 0,
      );

      int sellId = await SellDatabase().storeSell(sell);
      for (var item in widget.cartItems) {
        await SellDatabase().store({
          'sell_id': sellId,
          'product_id': item['product_id'] ?? 0,
          'variation_id': item['variation_id'] ?? 0,
          'quantity': (item['quantity'] as num?)?.toDouble() ?? 1.0,
          'unit_price': (item['unit_price'] as num?)?.toDouble() ?? 0.0,
          'tax_rate_id': 0,
          'discount_type': 'fixed',
          'discount_amount': 0.0,
          'is_completed': 1,
        });
      }
      for (int i = 0; i < payments.length; i++) {
        await Sell().makePayment([
          {
            'amount': payments[i]['amount'],
            'method': payments[i]['method'],
            'note': paymentNoteControllers[i].text,
            'account_id': payments[i]['account_id'],
          }
        ], sellId);
      }
      SellDatabase().updateSellLine({'sell_id': sellId, 'is_completed': 1});

      bool isSynced = false;
      if (await Helper().checkConnectivity()) {
        try {
          await Sell().createApiSell(sellId: sellId);
          isSynced = true;
        } catch (_) {}
      }

      if (printInvoice) {
        try {
          await Helper().printDocument(sellId, 0, context);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Printing not available')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF sharing not available')),
          );
        }
      }

      if (mounted) {
        setState(() {
          isLoading = false;
        });
        widget.onPaymentCompleted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isSynced ? 'Payment Completed and Synced' : 'Payment Completed, Saved Locally',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment Failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    saleNoteController.dispose();
    staffNoteController.dispose();
    for (var controller in paymentAmountControllers) {
      controller.dispose();
    }
    for (var controller in paymentNoteControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);

    return Container(
      padding: EdgeInsets.all((MySize.size16 ?? 16.0).toDouble()),
      decoration: BoxDecoration(
        color: customAppTheme.bgLayer2,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular((MySize.size12 ?? 12.0).toDouble()),
          bottomRight: Radius.circular((MySize.size12 ?? 12.0).toDouble()),
        ),
      ),
      child: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: themeData.colorScheme.primary,
        ),
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Section: Payment Details and Notes
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('payment_details'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size18 ?? 18.0).toDouble(),
                    fontWeight: FontWeight.w600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: (MySize.size12 ?? 12.0).toDouble()),
                Text(
                  '${AppLocalizations.of(context).translate('advance_balance')}:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size16 ?? 16.0).toDouble(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$symbol${Helper().formatCurrency(advanceBalance)}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size16 ?? 16.0).toDouble(),
                    color: themeData.colorScheme.primary,
                  ),
                ),
                SizedBox(height: (MySize.size12 ?? 12.0).toDouble()),
                Text(
                  '${AppLocalizations.of(context).translate('payment_details')}:',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size16 ?? 16.0).toDouble(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: (MySize.size4 ?? 4.0).toDouble()),
                      child: Padding(
                        padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: paymentAmountControllers[index],
                                    decoration: InputDecoration(
                                      labelText: '${AppLocalizations.of(context).translate('amount')} *',
                                      prefixText: symbol,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            (MySize.size8 ?? 8.0).toDouble()),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
                                    ],
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: (MySize.size14 ?? 14.0).toDouble(),
                                    ),
                                    onChanged: (value) {
                                      calculateMultiPayment();
                                    },
                                  ),
                                ),
                                if (index > 0)
                                  IconButton(
                                    icon: Icon(
                                      MdiIcons.delete,
                                      color: Colors.red,
                                      size: (MySize.size24 ?? 24.0).toDouble(),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        payments.removeAt(index);
                                        paymentAmountControllers.removeAt(index);
                                        paymentNoteControllers.removeAt(index);
                                        calculateMultiPayment();
                                      });
                                    },
                                  ),
                              ],
                            ),
                            SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: payments[index]['method'],
                                      hint: Text(
                                        AppLocalizations.of(context).translate('select_payment_method'),
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: (MySize.size14 ?? 14.0).toDouble(),
                                          color: themeData.colorScheme.onSurface.withAlpha(150),
                                        ),
                                      ),
                                      items: paymentMethods.map<DropdownMenuItem<String>>((method) {
                                        return DropdownMenuItem<String>(
                                          value: method['name'],
                                          child: Text(
                                            method['value']?.toString() ?? method['name'],
                                            style: TextStyle(
                                              fontFamily: 'Cairo',
                                              fontSize: (MySize.size14 ?? 14.0).toDouble(),
                                              color: themeData.colorScheme.onSurface,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          payments[index]['method'] = value;
                                          payments[index]['account_id'] = paymentMethods
                                              .firstWhere((m) => m['name'] == value)['account_id'];
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: (MySize.size8 ?? 8.0).toDouble()),
                                Expanded(
                                  child: TextFormField(
                                    controller: paymentNoteControllers[index],
                                    decoration: InputDecoration(
                                      labelText: '${AppLocalizations.of(context).translate('payment_note')}',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            (MySize.size8 ?? 8.0).toDouble()),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: (MySize.size14 ?? 14.0).toDouble(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      payments.add({
                        'amount': pendingAmount > 0 ? pendingAmount : 0.0,
                        'method': paymentMethods.isNotEmpty ? paymentMethods[0]['name'] : 'cash',
                        'note': '',
                        'account_id': paymentMethods.isNotEmpty ? paymentMethods[0]['account_id'] : null,
                      });
                      paymentAmountControllers.add(TextEditingController(text: (pendingAmount > 0 ? pendingAmount : 0.0).toStringAsFixed(2)));
                      paymentNoteControllers.add(TextEditingController());
                      calculateMultiPayment();
                    });
                  },
                  icon: Icon(Icons.add, size: (MySize.size18 ?? 18.0).toDouble()),
                  label: Text(
                    AppLocalizations.of(context).translate('add_payment_row'),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: (MySize.size14 ?? 14.0).toDouble(),
                      color: themeData.colorScheme.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeData.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: (MySize.size16 ?? 16.0).toDouble(),
                      vertical: (MySize.size8 ?? 8.0).toDouble(),
                    ),
                  ),
                ),
                SizedBox(height: (MySize.size16 ?? 16.0).toDouble()),
                TextFormField(
                  controller: saleNoteController,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context).translate('sell_note')}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  ),
                ),
                SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
                TextFormField(
                  controller: staffNoteController,
                  decoration: InputDecoration(
                    labelText: '${AppLocalizations.of(context).translate('staff_note')}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  ),
                ),
              ],
            ),
          ),
          // Right Section: Summary
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all((MySize.size12 ?? 12.0).toDouble()),
              margin: EdgeInsets.only(left: (MySize.size16 ?? 16.0).toDouble()),
              decoration: BoxDecoration(
                color: customAppTheme.colorWarning,
                borderRadius: BorderRadius.circular((MySize.size12 ?? 12.0).toDouble()),
                boxShadow: [
                  BoxShadow(
                    color: customAppTheme.shadowColor.withAlpha(48),
                    blurRadius: (MySize.size8 ?? 8.0).toDouble(),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).translate('summary'),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: (MySize.size18 ?? 18.0).toDouble(),
                      fontWeight: FontWeight.w600,
                      color: customAppTheme.onWarning,
                    ),
                  ),
                  SizedBox(height: (MySize.size12 ?? 12.0).toDouble()),
                  _buildSummaryRow(
                    AppLocalizations.of(context).translate('total_items'),
                    '${widget.cartItems.length.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow(
                    AppLocalizations.of(context).translate('total_payable'),
                    '$symbol${Helper().formatCurrency(widget.invoiceAmount - advanceBalance.clamp(0.0, widget.invoiceAmount))}',
                  ),
                  _buildSummaryRow(
                    AppLocalizations.of(context).translate('total_paying'),
                    '$symbol${Helper().formatCurrency(totalPaying)}',
                  ),
                  _buildSummaryRow(
                    AppLocalizations.of(context).translate('change_return'),
                    '$symbol${Helper().formatCurrency(changeReturn)}',
                  ),
                  _buildSummaryRow(
                    AppLocalizations.of(context).translate('balance'),
                    '$symbol${Helper().formatCurrency(pendingAmount)}',
                    color: pendingAmount > 0 ? Colors.red : customAppTheme.onWarning,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: (MySize.size4 ?? 4.0).toDouble()),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: (MySize.size14 ?? 14.0).toDouble(),
              fontWeight: FontWeight.w500,
              color: customAppTheme.onWarning,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: (MySize.size14 ?? 14.0).toDouble(),
              fontWeight: FontWeight.w600,
              color: color ?? customAppTheme.onWarning,
            ),
          ),
        ],
      ),
    );
  }

  void _showPendingAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('pending_amount'),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: (MySize.size16 ?? 16.0).toDouble(),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          AppLocalizations.of(context).translate('there_is_pending_amount_proceed'),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: (MySize.size14 ?? 14.0).toDouble(),
            color: themeData.colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context).translate('cancel'),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: (MySize.size14 ?? 14.0).toDouble(),
                color: themeData.colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onSubmit();
            },
            child: Text(
              AppLocalizations.of(context).translate('ok'),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: (MySize.size14 ?? 14.0).toDouble(),
                color: themeData.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}