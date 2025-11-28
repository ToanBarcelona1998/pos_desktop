import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/system.dart';

class CartSummary extends StatefulWidget {
  final List<dynamic> cartItems;
  final int? branchId;
  final int? customerId;
  final Function(List<dynamic>, double, double, String, int?) onCartUpdated;
  final TextEditingController discountController;

  const CartSummary({
    super.key,
    required this.cartItems,
    this.branchId,
    this.customerId,
    required this.onCartUpdated,
    required this.discountController,
  });

  @override
  CartSummaryState createState() => CartSummaryState();
}

class CartSummaryState extends State<CartSummary> {
  String symbol = '';
  double subTotal = 0.0;
  List<Map<String, dynamic>> taxList = [
    {'id': 0, 'name': 'no_tax', 'amount': 0.0}
  ];
  int? selectedTaxId = 0;
  String selectedDiscountType = 'fixed';
  double discountAmount = 0.0;
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);
  Map<int, TextEditingController> itemDiscountControllers = {};

  @override
  void initState() {
    super.initState();
    initializeData();
    calculateSubTotal();
    widget.discountController.addListener(() {
      setState(() {
        discountAmount = Helper().validateInput(widget.discountController.text);
        calculateSubTotal();
      });
    });
  }

  Future<void> initializeData() async {
    await Helper().getFormattedBusinessDetails().then((value) {
      if (mounted) {
        setState(() {
          symbol = value['symbol'] != null ? value['symbol'] + ' ' : '';
        });
      }
    });
    await fetchTaxes();
    await setDefaultValues();
    _initializeItemDiscountControllers();
  }

  Future<void> fetchTaxes() async {
    await System().get('tax').then((value) {
      if (mounted) {
        setState(() {
          taxList.clear();
          taxList.add({'id': 0, 'name': 'no_tax', 'amount': 0.0});
          if (value != null) {
            for (var element in value) {
              if (element['id'] != null && element['name'] != null) {
                taxList.add({
                  'id': element['id'] as int,
                  'name': element['name'] as String,
                  'amount': double.tryParse(element['amount']?.toString() ?? '0.0') ?? 0.0,
                });
              }
            }
          }
        });
      }
    });
  }

  Future<void> setDefaultValues() async {
    var businessDetails = await System().get('business');
    if (mounted && businessDetails.isNotEmpty) {
      if (businessDetails[0]['default_sales_tax'] != null) {
        setState(() {
          selectedTaxId = int.tryParse(businessDetails[0]['default_sales_tax'].toString()) ?? 0;
        });
      }
      if (businessDetails[0]['default_sales_discount'] != null) {
        setState(() {
          selectedDiscountType = 'percentage';
          discountAmount = double.tryParse(businessDetails[0]['default_sales_discount'].toString()) ?? 0.0;
          widget.discountController.text = discountAmount.toString();
        });
      }
    }
  }

  void _initializeItemDiscountControllers() {
    for (var i = 0; i < widget.cartItems.length; i++) {
      final item = widget.cartItems[i];
      itemDiscountControllers[i] = TextEditingController(
        text: (item['discount_amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00',
      );
      itemDiscountControllers[i]!.addListener(() {
        setState(() {
          double newDiscount = Helper().validateInput(itemDiscountControllers[i]!.text);
          widget.cartItems[i]['discount_amount'] = newDiscount;
          calculateSubTotal();
        });
      });
    }
  }

  void calculateSubTotal() async {
    double total = 0.0;
    for (var item in widget.cartItems) {
      double unitPrice = (item['unit_price'] as num?)?.toDouble() ?? 0.0;
      double quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
      double itemDiscount = (item['discount_amount'] as num?)?.toDouble() ?? 0.0;
      String itemDiscountType = item['discount_type']?.toString() ?? 'fixed';

      double itemTotal = unitPrice * quantity;
      if (itemDiscountType == 'fixed') {
        itemTotal -= itemDiscount;
      } else {
        itemTotal -= (itemTotal * itemDiscount / 100);
      }

      var taxResult = await Helper().calculateTaxAndDiscount(
        unitPrice: unitPrice,
        discountAmount: itemDiscount,
        discountType: itemDiscountType,
        taxId: selectedTaxId,
        quantity: quantity,
      );
      itemTotal += taxResult['taxAmount'] ?? 0.0;
      total += itemTotal;
    }

    double taxAmount = 0.0;
    for (var tax in taxList) {
      if (tax['id'] == selectedTaxId) {
        taxAmount = (tax['amount'] as num?)?.toDouble() ?? 0.0;
      }
    }

    double discountedTotal;
    if (selectedDiscountType == 'fixed') {
      discountedTotal = total - discountAmount;
    } else {
      discountedTotal = total - (total * discountAmount / 100);
    }
    discountedTotal = discountedTotal + (discountedTotal * taxAmount / 100);
    total = total + (total * taxAmount / 100);

    setState(() {
      subTotal = discountedTotal;
    });
    widget.onCartUpdated(widget.cartItems, total, discountAmount, selectedDiscountType, selectedTaxId);
  }

  void updateQuantity(int index, double newQuantity) async {
    double stockAvailable = (widget.cartItems[index]['stock_available'] as num?)?.toDouble() ?? 0.0;
    if (newQuantity > 0 && newQuantity <= stockAvailable) {
      setState(() {
        widget.cartItems[index]['quantity'] = newQuantity;
      });
      calculateSubTotal();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('stock_available_message').replaceAll('{0}', stockAvailable.toString())),
        ),
      );
    }
  }

  void updateItemDiscountType(int index, String newType) {
    setState(() {
      widget.cartItems[index]['discount_type'] = newType;
      calculateSubTotal();
    });
  }

  void removeItem(int index) {
    setState(() {
      itemDiscountControllers[index]?.dispose();
      itemDiscountControllers.remove(index);
      widget.cartItems[index]['quantity'] = null;
      widget.cartItems[index]['discount_amount'] = null;
      widget.cartItems[index]['discount_type'] = null;
      widget.cartItems.removeAt(index);
      _reindexDiscountControllers();
    });
    calculateSubTotal();
  }

  void _reindexDiscountControllers() {
    Map<int, TextEditingController> newControllers = {};
    for (var i = 0; i < widget.cartItems.length; i++) {
      newControllers[i] = itemDiscountControllers[i] ?? TextEditingController(text: '0.00');
      newControllers[i]!.text = (widget.cartItems[i]['discount_amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '0.00';
      newControllers[i]!.addListener(() {
        setState(() {
          double newDiscount = Helper().validateInput(newControllers[i]!.text);
          widget.cartItems[i]['discount_amount'] = newDiscount;
          calculateSubTotal();
        });
      });
    }
    itemDiscountControllers = newControllers;
  }

  @override
  void dispose() {
    itemDiscountControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CartSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cartItems != widget.cartItems) {
      _reindexDiscountControllers();
      calculateSubTotal();
    }
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);

    return Container(
      padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((MySize.size12 ?? 12.0).toDouble()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('cart'),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size18 ?? 18.0).toDouble(),
                  fontWeight: FontWeight.w600,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${AppLocalizations.of(context).translate('products')}: ${widget.cartItems.length}',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: (MySize.size14 ?? 14.0).toDouble(),
                      color: themeData.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  Visibility(
                    visible: widget.cartItems.isNotEmpty,
                    child: IconButton(
                      onPressed: () {
                        deleteConfirmationDialog(
                          onConfirm: () {
                            setState(() {
                              for (var item in widget.cartItems) {
                                item['quantity'] = null;
                                item['discount_amount'] = null;
                                item['discount_type'] = null;
                              }
                              itemDiscountControllers.forEach((_, controller) => controller.dispose());
                              itemDiscountControllers.clear();
                              widget.cartItems.clear();
                              calculateSubTotal();
                            });
                          },
                        );
                      },
                      icon: Icon(Icons.delete_forever_outlined),
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
          Expanded(
            child: widget.cartItems.isEmpty
                ? Center(
              child: Text(
                AppLocalizations.of(context).translate('add_item_to_cart'),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size16 ?? 16.0).toDouble(),
                  color: themeData.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            )
                : ListView.builder(
              itemCount: widget.cartItems.length,
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: (MySize.size4 ?? 4.0).toDouble()),
                  child: ListTile(
                    leading: Icon(
                      MdiIcons.cartOutline,
                      color: themeData.colorScheme.primary,
                      size: (MySize.size24 ?? 24.0).toDouble(),
                    ),
                    title: Text(
                      item['display_name']?.toString() ?? '',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: (MySize.size14 ?? 14.0).toDouble(),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$symbol${Helper().formatCurrency(item['unit_price'] ?? 0.0)}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: (MySize.size12 ?? 12.0).toDouble(),
                            color: themeData.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                        SizedBox(height: (MySize.size4 ?? 4.0).toDouble()),
                        Row(
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('discount'),
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: (MySize.size12 ?? 12.0).toDouble(),
                                color: themeData.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: (MySize.size8 ?? 8.0).toDouble()),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: item['discount_type']?.toString() ?? 'fixed',
                                dropdownColor: Colors.white,
                                items: ['fixed', 'percentage'].map<DropdownMenuItem<String>>((type) {
                                  return DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(
                                      AppLocalizations.of(context).translate(type),
                                      style: TextStyle(
                                        fontFamily: 'Cairo',
                                        fontSize: (MySize.size12 ?? 12.0).toDouble(),
                                        color: themeData.colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  updateItemDiscountType(index, newValue!);
                                },
                              ),
                            ),
                            SizedBox(width: (MySize.size8 ?? 8.0).toDouble()),
                            SizedBox(
                              width: (MySize.size80 ?? 80.0).toDouble(),
                              child: TextField(
                                controller: itemDiscountControllers[index],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')),
                                ],
                                decoration: InputDecoration(
                                  prefixText: item['discount_type'] == 'fixed' ? symbol : '% ',
                                  hintText: '0.00',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                                  ),
                                ),
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: (MySize.size12 ?? 12.0).toDouble(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            MdiIcons.minus,
                            size: (MySize.size20 ?? 20.0).toDouble(),
                            color: Colors.red,
                          ),
                          onPressed: () {
                            if (((item['quantity'] as num?)?.toDouble() ?? 1.0) > 1) {
                              updateQuantity(index, ((item['quantity'] as num?)?.toDouble() ?? 1.0) - 1);
                            } else {
                              deleteConfirmationDialog(onConfirm: () => removeItem(index));
                            }
                          },
                        ),
                        SizedBox(
                          width: (MySize.size40 ?? 40.0).toDouble(),
                          child: Text(
                            '${(item['quantity'] as num?)?.toDouble() ?? 1.0}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: (MySize.size14 ?? 14.0).toDouble(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            MdiIcons.plus,
                            size: (MySize.size20 ?? 20.0).toDouble(),
                            color: Colors.green,
                          ),
                          onPressed: () {
                            updateQuantity(index, ((item['quantity'] as num?)?.toDouble() ?? 1.0) + 1);
                          },
                        ),
                        Text(
                          '$symbol${Helper().formatCurrency(
                              ((item['unit_price'] as num?)?.toDouble() ?? 0.0) * ((item['quantity'] as num?)?.toDouble() ?? 1.0)
                          )}',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: (MySize.size14 ?? 14.0).toDouble(),
                            color: themeData.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            MdiIcons.delete,
                            size: (MySize.size20 ?? 20.0).toDouble(),
                            color: Colors.red,
                          ),
                          onPressed: () => deleteConfirmationDialog(onConfirm: () => removeItem(index)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('tax'),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selectedTaxId,
                  dropdownColor: Colors.white,
                  items: taxList.map<DropdownMenuItem<int>>((tax) {
                    return DropdownMenuItem<int>(
                      value: tax['id'],
                      child: Text(
                        tax['name'] != null && tax['name'] == 'no_tax'
                            ? AppLocalizations.of(context).translate(tax['name'])
                            : tax['name']?.toString() ?? '',
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: (MySize.size14 ?? 14.0).toDouble(),
                          color: themeData.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedTaxId = newValue;
                      calculateSubTotal();
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('discount'),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedDiscountType,
                      dropdownColor: Colors.white,
                      items: ['fixed', 'percentage'].map<DropdownMenuItem<String>>((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            AppLocalizations.of(context).translate(type),
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: (MySize.size14 ?? 14.0).toDouble(),
                              color: themeData.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedDiscountType = newValue!;
                          calculateSubTotal();
                        });
                      },
                    ),
                  ),
                  SizedBox(width: (MySize.size8 ?? 8.0).toDouble()),
                  SizedBox(
                    width: (MySize.size100 ?? 100.0).toDouble(),
                    child: TextField(
                      controller: widget.discountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        prefixText: selectedDiscountType == 'fixed' ? symbol : '% ',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
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
          SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('total'),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size16 ?? 16.0).toDouble(),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${Helper().formatCurrency(subTotal)} $symbol',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size16 ?? 16.0).toDouble(),
                  fontWeight: FontWeight.w700,
                  color: themeData.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void deleteConfirmationDialog({VoidCallback? onConfirm}) {
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
            onPressed: () {
              Navigator.of(context).pop();
              if (onConfirm != null) onConfirm();
            },
            child: Text(AppLocalizations.of(context).translate('yes')),
          ),
        ],
      ),
    );
  }
}