import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/apis/expenses.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/expenses.dart';
import 'package:pos_final/models/system.dart';

class Expense extends StatefulWidget {
  const Expense({super.key});

  @override
  ExpenseState createState() => ExpenseState();
}

class ExpenseState extends State<Expense> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> expenseCategories = [
        {'id': 0, 'name': 'Select', 'sub_categories': []}
      ],
      expenseSubCategories = [],
      paymentMethods = [],
      paymentAccounts = [],
      locationListMap = [
        {'id': 0, 'name': 'set location'}
      ],
      taxListMap = [
        {'id': 0, 'name': 'Tax rate', 'amount': 0}
      ];
  Map<String, dynamic> selectedLocation = {'id': 0, 'name': 'set location'},
      selectedTax = {'id': 0, 'name': 'Tax rate', 'amount': 0},
      selectedExpenseCategoryId = {'id': 0, 'name': 'Select'},
      selectedExpenseSubCategoryId = {'id': 0, 'name': 'Select'};
  TextEditingController expenseAmount = TextEditingController(),
      expenseNote = TextEditingController(),
      payingAmount = TextEditingController();

  Map<String, dynamic> selectedPaymentAccount = {'id': null, 'name': 'None'},
      selectedPaymentMethod = {'name': 'name', 'value': 'Select Method', 'account_id': null};
  String symbol = '';
  bool isSubmitting = false;
  bool dataLoading = true;

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => dataLoading = true);
    await Future.wait([
      setLocationMap(),
      setTaxMap(),
      setExpenseCategories(),
      setPaymentDetails(selectedLocation['id']),
    ]);
    setState(() => dataLoading = false);
    Helper().syncCallLogs();
  }

  @override
  void dispose() {
    expenseAmount.dispose();
    expenseNote.dispose();
    payingAmount.dispose();
    super.dispose();
  }

  String safeTranslate(String key, {String fallback = ''}) {
    try {
      return AppLocalizations.of(context).translate(key);
    } catch (e) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: Text(
          safeTranslate('expenses', fallback: 'Expenses'),
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              FontAwesomeIcons.arrowRotateRight,
              color: themeData.colorScheme.primary,
              size: 20,
            ),
            onPressed: resetForm,
            tooltip: safeTranslate('clear_form', fallback: 'Clear Form'),
          ),
          SizedBox(width: MySize.size16!),
        ],
      ),
      body: isSubmitting || dataLoading
          ? Center(child: CircularProgressIndicator(color: themeData.colorScheme.primary))
          : Padding(
              padding: EdgeInsets.all(MySize.size24!),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildExpenseDetailsCard(),
                    ),
                    SizedBox(width: MySize.size24!),
                    Expanded(
                      child: Column(
                        children: [
                          _buildPaymentDetailsCard(),
                          SizedBox(height: MySize.size24!),
                          _buildSummaryCard(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildExpenseDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(MySize.size24!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              safeTranslate('expense_details', fallback: 'Expense Details'),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: themeData.colorScheme.primary,
              ),
            ),
            SizedBox(height: MySize.size16!),
            _buildDropdownField(
              label: safeTranslate('location', fallback: 'Location'),
              icon: FontAwesomeIcons.locationDot,
              value: selectedLocation,
              items: locationListMap,
              onChanged: (value) {
                setState(() {
                  selectedLocation = value!;
                  setExpenseCategories();
                  setPaymentDetails(selectedLocation['id']).then((_) {
                    setState(() {
                      selectedPaymentMethod = paymentMethods.isNotEmpty
                          ? paymentMethods[0]
                          : {'name': 'name', 'value': 'Select Method', 'account_id': null};
                      selectedPaymentAccount = paymentAccounts.isNotEmpty
                          ? paymentAccounts[0]
                          : {'id': null, 'name': 'None'};
                      for (var element in paymentAccounts) {
                        if (selectedPaymentMethod['account_id'] == element['id']) {
                          selectedPaymentAccount = element;
                        }
                      }
                    });
                  });
                });
              },
              validator: (value) => value!['id'] == 0
                  ? safeTranslate('select_location', fallback: 'Please select a location')
                  : null,
            ),
            SizedBox(height: MySize.size16!),
            _buildDropdownField(
              label: safeTranslate('tax', fallback: 'Tax'),
              icon: FontAwesomeIcons.percent,
              value: selectedTax,
              items: taxListMap,
              onChanged: (value) => setState(() => selectedTax = value!),
              displayText: (item) => '${item['name']} (${item['amount']}%)',
            ),
            SizedBox(height: MySize.size16!),
            _buildDropdownField(
              label: safeTranslate('expense_categories', fallback: 'Expense Category'),
              icon: FontAwesomeIcons.list,
              value: selectedExpenseCategoryId,
              items: expenseCategories,
              onChanged: (value) {
                setState(() {
                  selectedExpenseCategoryId = value!;
                  selectedExpenseSubCategoryId = {'id': 0, 'name': 'Select'};
                  expenseSubCategories = [];
                  if (value.containsKey('sub_categories') && value['sub_categories'].isNotEmpty) {
                    value['sub_categories'].forEach((element) {
                      expenseSubCategories.add({'id': element['id'], 'name': element['name']});
                    });
                  }
                });
              },
              validator: (value) => value!['id'] == 0
                  ? safeTranslate('select_category', fallback: 'Please select a category')
                  : null,
            ),
            SizedBox(height: MySize.size16!),
            _buildDropdownField(
              label: safeTranslate('sub_categories', fallback: 'Sub Category'),
              icon: FontAwesomeIcons.listUl,
              value: selectedExpenseSubCategoryId,
              items: expenseSubCategories.isEmpty
                  ? [
                      {'id': 0, 'name': 'Select'}
                    ]
                  : expenseSubCategories,
              onChanged: (value) => setState(() => selectedExpenseSubCategoryId = value!),
            ),
            SizedBox(height: MySize.size16!),
            _buildTextField(
              controller: expenseAmount,
              label: safeTranslate('expense_amount', fallback: 'Expense Amount'),
              icon: FontAwesomeIcons.dollarSign,
              prefix: Text(symbol.isEmpty ? '' : symbol, style: textStyle()),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) => value!.isEmpty
                  ? safeTranslate('please_enter_expense_amount',
                      fallback: 'Please enter expense amount')
                  : null,
            ),
            SizedBox(height: MySize.size16!),
            _buildTextField(
              controller: expenseNote,
              label: safeTranslate('expense_note', fallback: 'Expense Note'),
              icon: FontAwesomeIcons.noteSticky,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(MySize.size24!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              safeTranslate('payment_details', fallback: 'Payment Details'),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: themeData.colorScheme.primary,
              ),
            ),
            SizedBox(height: MySize.size16!),
            _buildTextField(
              controller: payingAmount,
              label: safeTranslate('payment_amount', fallback: 'Payment Amount'),
              icon: FontAwesomeIcons.dollarSign,
              prefix: Text(symbol.isEmpty ? '' : symbol, style: textStyle()),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value!.isEmpty) value = '0.00';
                final expense = double.tryParse(expenseAmount.text) ?? 0;
                final paying = double.tryParse(value) ?? 0;
                if (expense > 0 && paying > expense) {
                  return safeTranslate('enter_valid_payment_amount',
                      fallback: 'Payment amount exceeds expense');
                }
                return null;
              },
            ),
            SizedBox(height: MySize.size16!),
            _buildDropdownField(
              label: safeTranslate('payment_method', fallback: 'Payment Method'),
              icon: FontAwesomeIcons.creditCard,
              value: selectedPaymentMethod,
              items: paymentMethods.isEmpty
                  ? [
                      {'name': 'name', 'value': 'Select Method', 'account_id': null}
                    ]
                  : paymentMethods,
              onChanged: (value) {
                setState(() {
                  selectedPaymentMethod = value!;
                  selectedPaymentAccount = paymentAccounts.isNotEmpty
                      ? paymentAccounts[0]
                      : {'id': null, 'name': 'None'};
                  for (var element in paymentAccounts) {
                    if (selectedPaymentMethod['account_id'] == element['id']) {
                      selectedPaymentAccount = element;
                    }
                  }
                });
              },
              displayText: (item) => item['value'],
            ),
            SizedBox(height: MySize.size16!),
            _buildDropdownField(
              label: safeTranslate('payment_account', fallback: 'Payment Account'),
              icon: FontAwesomeIcons.wallet,
              value: selectedPaymentAccount,
              items: paymentAccounts.isEmpty
                  ? [
                      {'id': null, 'name': 'None'}
                    ]
                  : paymentAccounts,
              onChanged: (value) {
                setState(() {
                  selectedPaymentAccount = value!;
                  selectedPaymentMethod['account_id'] = value['id'];
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final expense = double.tryParse(expenseAmount.text) ?? 0;
    final taxRate = selectedTax['amount'] as num? ?? 0;
    final taxAmount = expense * (taxRate / 100);
    final total = expense + taxAmount;
    final paying = double.tryParse(payingAmount.text) ?? 0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeData.colorScheme.primary,
              themeData.colorScheme.primary.withAlpha((0.7 * 256).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(MySize.size24!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              safeTranslate('expense_summary', fallback: 'Expense Summary'),
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: MySize.size16!),
            _summaryRow(
              label: safeTranslate('expense_amount', fallback: 'Expense Amount'),
              value: '${symbol.isEmpty ? '' : symbol}${expense.toStringAsFixed(2)}',
            ),
            _summaryRow(
              label: '${safeTranslate('tax', fallback: 'Tax')} (${taxRate.toStringAsFixed(0)}%)',
              value: '${symbol.isEmpty ? '' : symbol}${taxAmount.toStringAsFixed(2)}',
            ),
            _summaryRow(
              label: safeTranslate('total', fallback: 'Total'),
              value: '${symbol.isEmpty ? '' : symbol}${total.toStringAsFixed(2)}',
              isBold: true,
            ),
            _summaryRow(
              label: safeTranslate('payment_amount', fallback: 'Payment Amount'),
              value: '${symbol.isEmpty ? '' : symbol}${paying.toStringAsFixed(2)}',
            ),
            SizedBox(height: MySize.size24!),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: themeData.colorScheme.primary,
                  padding:
                      EdgeInsets.symmetric(horizontal: MySize.size24!, vertical: MySize.size12!),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: Icon(FontAwesomeIcons.check),
                label: Text(
                  safeTranslate('submit', fallback: 'Submit'),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onPressed: () async {
                  if (await Helper().checkConnectivity()) {
                    if (_formKey.currentState!.validate()) {
                      await onSubmit();
                    }
                  } else {
                    Fluttertoast.showToast(
                        msg: safeTranslate('check_connectivity',
                            fallback: 'Please check your internet connection'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required Map<String, dynamic> value,
    required List<Map<String, dynamic>> items,
    required ValueChanged<Map<String, dynamic>?> onChanged,
    String Function(Map<String, dynamic>)? displayText,
    String? Function(Map<String, dynamic>?)? validator,
  }) {
    if (items.isEmpty) {
      return TextFormField(
        enabled: false,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon, color: themeData.colorScheme.primary.withAlpha((0.5 * 256).toInt())),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          hintText: safeTranslate('no_options', fallback: 'No options available'),
        ),
        style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: themeData.colorScheme.onSurface),
      );
    }

    final selectedValue = items.contains(value) ? value : items[0];

    return DropdownButtonFormField<Map<String, dynamic>>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2),
        ),
      ),
      style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: themeData.colorScheme.onSurface),
      dropdownColor: themeData.colorScheme.surface,
      // Ensure dropdown background is visible
      items: items.map((item) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: item,
          child: Text(
            displayText != null ? displayText(item) : item['name'],
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: themeData.colorScheme.onSurface, // Ensure text is visible
            ),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Widget? prefix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: themeData.colorScheme.primary),
        prefix: prefix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2),
        ),
      ),
      style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: themeData.colorScheme.onSurface),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
    );
  }

  Widget _summaryRow({
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MySize.size4!),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.white,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      selectedLocation = locationListMap[0];
      selectedTax = taxListMap[0];
      selectedExpenseCategoryId = expenseCategories[0];
      selectedExpenseSubCategoryId = {'id': 0, 'name': 'Select'};
      selectedPaymentMethod = paymentMethods.isNotEmpty
          ? paymentMethods[0]
          : {'name': 'name', 'value': 'Select Method', 'account_id': null};
      selectedPaymentAccount =
          paymentAccounts.isNotEmpty ? paymentAccounts[0] : {'id': null, 'name': 'None'};
      expenseAmount.clear();
      expenseNote.clear();
      payingAmount.clear();
    });
  }

  Future<void> setLocationMap() async {
    locationListMap = [
      {'id': 0, 'name': safeTranslate('set_location', fallback: 'set location')}
    ];
    final value = await System().get('location');
    setState(() {
      value.forEach((element) {
        locationListMap.add({
          'id': element['id'],
          'name': element['name'],
        });
      });
    });
  }

  Future<void> setTaxMap() async {
    final value = await System().get('tax');
    setState(() {
      taxListMap = [
        {'id': 0, 'name': safeTranslate('tax_rate', fallback: 'Tax rate'), 'amount': 0}
      ];
      value.forEach((element) {
        taxListMap.add({'id': element['id'], 'name': element['name'], 'amount': element['amount']});
      });
    });
  }

  Future<void> setExpenseCategories() async {
    expenseCategories = [
      {'id': 0, 'name': 'Select', 'sub_categories': []}
    ];
    final value = await ExpenseApi().get();
    setState(() {
      for (var element in value) {
        expenseCategories.add({
          'id': element['id'],
          'name': element['name'],
          'sub_categories': element['sub_categories']
        });
      }
    });
  }

  Future<void> setPaymentDetails(int locId) async {
    final businessDetails = await Helper().getFormattedBusinessDetails();
    setState(() {
      symbol = businessDetails['symbol'] ?? '';
    });
    final payments = await System().get('payment_method', locId);
    final accounts = await System().getPaymentAccounts();
    setState(() {
      paymentAccounts = [
        {'id': null, 'name': safeTranslate('none', fallback: 'None')}
      ];
      List<String> accIds = [];
      for (var element in accounts) {
        for (var payment in payments) {
          if ((payment['account_id']?.toString() == element['id'].toString()) &&
              !accIds.contains(element['id'].toString())) {
            accIds.add(element['id'].toString());
            paymentAccounts.add({'id': element['id'], 'name': element['name']});
          }
        }
      }
      paymentMethods = [
        {
          'name': 'name',
          'value': safeTranslate('select_method', fallback: 'Select Method'),
          'account_id': null
        }
      ];
      for (var element in payments) {
        paymentMethods.add({
          'name': element['name'],
          'value': element['label'],
          'account_id':
              element['account_id'] != null ? int.parse(element['account_id'].toString()) : null
        });
      }
      selectedPaymentMethod = paymentMethods.isNotEmpty
          ? paymentMethods[0]
          : {'name': 'name', 'value': 'Select Method', 'account_id': null};
      selectedPaymentAccount =
          paymentAccounts.isNotEmpty ? paymentAccounts[0] : {'id': null, 'name': 'None'};
    });
  }

  Future<void> onSubmit() async {
    setState(() => isSubmitting = true);
    try {
      if (selectedLocation['id'] != 0) {
        final expenseText = expenseAmount.text.isEmpty ? '0.00' : expenseAmount.text;
        final payingText = payingAmount.text.isEmpty ? '0.00' : payingAmount.text;
        final expenseMap = ExpenseManagement().createExpense(
          locId: selectedLocation['id'],
          finalTotal: double.parse(expenseText),
          amount: double.parse(payingText),
          method: selectedPaymentMethod['name'],
          accountId: selectedPaymentAccount['id'],
          expenseCategoryId: selectedExpenseCategoryId['id'],
          expenseSubCategoryId: selectedExpenseSubCategoryId['id'],
          taxId: selectedTax['id'] != 0 ? selectedTax['id'] : null,
          note: expenseNote.text,
        );
        await ExpenseApi().create(expenseMap);
        Navigator.pop(context);
        Fluttertoast.showToast(
            msg: safeTranslate('expense_added_successfully',
                fallback: 'Expense added successfully'));
      } else {
        Fluttertoast.showToast(
            msg: safeTranslate('error_invalid_location', fallback: 'Invalid location selected'));
      }
    } catch (e) {
      Fluttertoast.showToast(
          msg: safeTranslate('error_submission', fallback: 'Failed to submit expense'));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  TextStyle textStyle() {
    return TextStyle(
      fontFamily: 'Cairo',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: themeData.colorScheme.onSurface,
    );
  }
}
