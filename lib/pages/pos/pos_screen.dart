import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pos_final/config.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/database.dart';
import 'package:pos_final/models/invoice_type.dart';
import 'package:pos_final/models/sell.dart';
import 'package:pos_final/models/sell_database.dart';
import 'package:pos_final/pages/pos/widgets/branch_selector.dart';
import 'package:pos_final/pages/pos/widgets/custom_snackbar.dart';
import 'package:pos_final/pages/pos/widgets/customer_selector.dart';
import 'package:pos_final/pages/pos/widgets/date_time_selector.dart';
import 'package:pos_final/pages/pos/widgets/invoice_type_selector.dart';
import 'package:pos_final/pages/pos/widgets/payment_section.dart';
import 'package:pos_final/pages/pos/widgets/product_grid.dart';
import 'package:pos_final/pages/pos/widgets/cart_summary.dart';
import 'package:pos_final/pages/pos/widgets/shipping_details.dart';
import 'package:pos_final/pages/pos/widgets/suspended_sales_list.dart';
import 'package:window_manager/window_manager.dart';

import '../../models/system.dart';

// Enum for payment methods
enum PaymentMethod { cash, card, cheque, bankTransfer }

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  PosScreenState createState() => PosScreenState();
}

class PosScreenState extends State<PosScreen> {
  static int themeType = 1;
  String symbol = '';
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);
  Size? previousSize;
  Offset? previousPosition;
  int? selectedBranchId;
  Map<String, dynamic>? selectedCustomer;
  List<dynamic> cartItems = [];
  double invoiceAmount = 0.0;
  DateTime selectedDate = DateTime.now();
  String discountType = 'fixed';
  double discountAmount = 0.0;
  int? taxId;
  String? invoiceType = 'final';
  bool isQuotation = false;
  bool isSuspend = false;
  double shippingCharges = 0.0;
  String? shippingDetails;
  String? shippingAddress;
  String? shippingStatus;
  String? deliveredTo;
  final TextEditingController discountController = TextEditingController();
  late AudioPlayer _player;
  Timer? _refreshTimer;
  final InvoiceType _invoiceTypeModel = InvoiceType();
  bool showShipping = false; // State to toggle shipping details visibility

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    initializeData();
    _refreshTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
      if (selectedBranchId != null && await Helper().checkConnectivity()) {
        await refreshProducts();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _player.dispose();
    discountController.dispose();
    super.dispose();
  }

  Future<void> initializeData() async {
    await Helper().getFormattedBusinessDetails().then((value) {
      if (mounted) {
        setState(() {
          symbol = value['symbol'] != null ? value['symbol'] + ' ' : '';
        });
      }
    });

    if (selectedBranchId == null) {
      final db = DbProvider.db;
      final locations = await System().get('location');
      if (locations.isNotEmpty) {
        if (mounted) {
          setState(() {
            selectedBranchId = locations[0]['id'] as int?;
          });
        }
      }
    }
  }

  void onBranchSelected(int? branchId) {
    if (mounted) {
      setState(() {
        selectedBranchId = branchId;
        cartItems.clear();
        invoiceAmount = 0.0;
        discountAmount = 0.0;
        discountController.clear();
        taxId = null;
        selectedCustomer = null;
        showShipping = false;
      });
    }
  }

  void onCustomerSelected(Map<String, dynamic>? customer) {
    if (mounted) {
      setState(() {
        selectedCustomer = customer;
      });
    }
  }

  void onInvoiceTypeSelected(String? type, bool? quotation, bool? suspend) {
    if (mounted) {
      setState(() {
        invoiceType = type;
        isQuotation = quotation ?? false;
        isSuspend = suspend ?? false;
      });
    }
  }

  void onCartUpdated(
      List<dynamic> updatedCart, double total, double amount, String type, int? tax) {
    Future.microtask(() {
      if (mounted) {
        setState(() {
          cartItems = updatedCart;
          invoiceAmount = total + shippingCharges;
          discountAmount = amount;
          discountType = type;
          taxId = tax;
        });
      }
    });
  }

  void onShippingDetailsChanged(Map<String, dynamic> shippingData) {
    if (mounted) {
      setState(() {
        shippingCharges = shippingData['shipping_charges'] ?? 0.0;
        shippingDetails = shippingData['shipping_details'];
        shippingAddress = shippingData['shipping_address'];
        shippingStatus = shippingData['shipping_status'];
        deliveredTo = shippingData['delivered_to'];
        invoiceAmount = (invoiceAmount - shippingCharges) + (shippingCharges);
      });
    }
  }

  void onPaymentCompleted() {
    if (mounted) {
      setState(() {
        for (var item in cartItems) {
          item['quantity'] = null;
          item['discount_amount'] = null;
          item['discount_type'] = null;
        }
        cartItems.clear();
        selectedCustomer = null;
        invoiceAmount = 0.0;
        discountAmount = 0.0;
        discountController.clear();
        taxId = null;
        invoiceType = 'final';
        isQuotation = false;
        isSuspend = false;
        shippingCharges = 0.0;
        shippingDetails = null;
        shippingAddress = null;
        shippingStatus = null;
        deliveredTo = null;
        showShipping = false;
      });
    }
  }

  Future<void> goToExpenses() async {
    if (await Helper().checkConnectivity()) {
      Navigator.pushNamed(context, '/expense');
    } else {
      _showErrorSnackBar(AppLocalizations.of(context).translate('check_connectivity'));
    }
  }

  Future<void> refreshProducts() async {
    if (selectedBranchId == null) return;
    try {
      final db = DbProvider.db;
      await db.clearProductsCache();
      _showSuccessSnackBar(AppLocalizations.of(context).translate('products_refreshed'));
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context).translate('refresh_failed'));
    }
  }

  Future<void> submitSale({bool isCredit = false, bool printInvoice = true}) async {
    if (selectedCustomer == null || selectedCustomer?['id'] == null || selectedCustomer?['id'] == 1) {
      _showErrorSnackBar(AppLocalizations.of(context).translate('select_customer_required'));
      return;
    }

    if (cartItems.isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context).translate('cart_empty'));
      return;
    }

    // Force shipping details to null/0 before submission
    shippingCharges = 0.0;
    shippingDetails = null;
    shippingAddress = null;
    shippingStatus = null;
    deliveredTo = null;

    try {
      final invoiceNo = "${Config.userId}_${DateFormat('yMdHm').format(DateTime.now())}";
      final adjustedInvoiceAmount = invoiceAmount -
          (discountType == 'percentage' ? invoiceAmount * discountAmount / 100 : discountAmount);

      final Map<String, dynamic> sellData = await Sell().createSell(
        invoiceNo: invoiceNo,
        transactionDate: selectedDate.toString(),
        contactId: selectedCustomer?['id'],
        discountAmount: discountAmount,
        discountType: discountType,
        invoiceAmount: adjustedInvoiceAmount + shippingCharges,
        locId: selectedBranchId,
        saleStatus: isCredit ? 'pending' : invoiceType,
        pending: isCredit ? adjustedInvoiceAmount : 0.0,
        taxId: taxId,
        isQuotation: isQuotation ? 1 : 0,
        isSuspend: isSuspend ? 1 : 0,
        shippingCharges: shippingCharges,
        shippingDetails: shippingDetails,
        shippingAddress: shippingAddress,
        shippingStatus: shippingStatus,
        deliveredTo: deliveredTo,
      );

      int? responseId = await SellDatabase().storeSell(sellData);

      if (!isQuotation && !isSuspend) {
        final paymentLines = [
          {
            'sell_id': responseId,
            'amount': isCredit ? 0 : adjustedInvoiceAmount,
            'payment_method': isCredit ? 'card' : 'cash',
            'note': '',
            'account_id': null,
            'transaction_date': selectedDate.toString(),
          }
        ];
        await Sell().makePayment(paymentLines, responseId);
      }

      await SellDatabase().updateSellLine({
        'sell_id': responseId,
        'is_completed': (isCredit || isQuotation || isSuspend) ? 0 : 1,
      });

      for (var cartItem in cartItems) {
        cartItem['tax_rate_id'] = taxId;
        cartItem['discount_amount'] = cartItem['discount_amount'] ?? 0.0;
        cartItem['discount_type'] = cartItem['discount_type'] ?? 'fixed';
        await Sell().addToCart(cartItem, responseId);
      }

      if (await Helper().checkConnectivity()) {
        await Sell().createApiSell(sellId: responseId);
        await DbProvider.db.updateProductsLastSync();
      }

      if (mounted) {
        _showSuccessSnackBar(AppLocalizations.of(context).translate(
            isQuotation ? 'quotation_added' : isSuspend ? 'suspended_sale_added' : 'invoice_success'));
      }

      await _player.play(AssetSource('audios/success.mp3'));

      if (printInvoice && !isSuspend) {
        showDialog(
          context: context,
          builder: (context) {
            return printInvoiceDialog(
              context,
                  () async {
                final sellDetail = await SellDatabase().getSellBySellId(responseId);
                final String? invoiceUrl = sellDetail[0]['invoice_url'];
                if (invoiceUrl != null) {
                  final response = await http.Client().get(Uri.parse(invoiceUrl));
                  if (response.statusCode == 200) {
                    await Helper().printDocument(responseId, taxId, context, invoice: response.body);
                  } else {
                    await Helper().printDocument(responseId, taxId, context);
                  }
                } else {
                  await Helper().printDocument(responseId, taxId, context);
                }
              },
            );
          },
        );
      }

      onPaymentCompleted();
    } catch (e) {
      await _player.play(AssetSource('audios/error.mp3'));
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  Future<void> showMultiPaymentDialog() async {
    if (selectedCustomer == null || selectedCustomer?['id'] == null || selectedCustomer?['id'] == 1) {
      _showErrorSnackBar(AppLocalizations.of(context).translate('select_customer_required'));
      return;
    }

    if (cartItems.isEmpty) {
      _showErrorSnackBar(AppLocalizations.of(context).translate('cart_empty'));
      return;
    }

    // Force shipping to 0 before passing to PaymentSection
    shippingCharges = 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular((MySize.size12 ?? 12.0).toDouble()),
          ),
          child: Container(
            padding: EdgeInsets.all((MySize.size16 ?? 16.0).toDouble()),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).translate('multi_payment'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size20 ?? 20.0).toDouble(),
                    fontWeight: FontWeight.w600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: (MySize.size16 ?? 16.0).toDouble()),
                Expanded(
                  child: PaymentSection(
                    invoiceAmount: invoiceAmount -
                        (discountType == 'percentage' ? invoiceAmount * discountAmount / 100 : discountAmount) +
                        shippingCharges,
                    branchId: selectedBranchId,
                    customerId: selectedCustomer?['id'],
                    cartItems: cartItems,
                    onPaymentCompleted: () {
                      Navigator.of(context).pop();
                      onPaymentCompleted();
                    },
                  ),
                ),
                SizedBox(height: (MySize.size16 ?? 16.0).toDouble()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customAppTheme.colorError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: (MySize.size16 ?? 16.0).toDouble(),
                          vertical: (MySize.size12 ?? 12.0).toDouble(),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('close'),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: (MySize.size14 ?? 14.0).toDouble(),
                          color: customAppTheme.onError,
                        ),
                      ),
                    ),
                    SizedBox(width: (MySize.size8 ?? 8.0).toDouble()),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await submitSale(printInvoice: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customAppTheme.colorInfo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: (MySize.size16 ?? 16.0).toDouble(),
                          vertical: (MySize.size12 ?? 12.0).toDouble(),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context).translate('finalize_payment'),
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: (MySize.size14 ?? 14.0).toDouble(),
                          color: customAppTheme.onInfo,
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
    );
  }

  Future<void> showSuspendedSalesDialog() async {
    showDialog(
      context: context,
      builder: (context) => SuspendedSalesList(
        onSaleSelected: (saleData) {
          if (mounted) {
            setState(() {
              final sale = saleData['sale'];
              cartItems = saleData['sell_lines'].map((line) => {
                'product_id': line['product_id'],
                'variation_id': line['variation_id'],
                'quantity': line['quantity'],
                'unit_price': line['unit_price'],
                'tax_rate_id': line['tax_rate_id'],
                'discount_amount': line['discount_amount'],
                'discount_type': line['discount_type'],
                'display_name': line['name'],
              }).toList();
              selectedCustomer = {'id': sale['contact_id']};
              invoiceAmount = sale['invoice_amount'] ?? 0.0;
              discountAmount = sale['discount_amount'] ?? 0.0;
              discountType = sale['discount_type'] ?? 'fixed';
              taxId = sale['tax_rate_id'];
              selectedDate = DateTime.parse(sale['transaction_date']);
              invoiceType = sale['status'];
              isQuotation = sale['is_quotation'] == 1;
              isSuspend = sale['is_suspend'] == 1;
              // Force shipping to null/0 when loading suspended sales
              shippingCharges = 0.0;
              shippingDetails = null;
              shippingAddress = null;
              shippingStatus = null;
              deliveredTo = null;
              discountController.text = discountAmount.toString();
            });
          }
        },
      ),
    );
  }

  Future<void> cancelSale() async {
    if (cartItems.isEmpty && selectedCustomer == null) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('confirm')),
        content: Text(AppLocalizations.of(context).translate('are_you_sure_cancel')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).translate('no')),
          ),
          TextButton(
            onPressed: () async {
              try {
                if (await Helper().checkConnectivity()) {
                  final db = await DbProvider.db.database;
                  final sales = await db.query('sell', where: 'is_synced = ?', whereArgs: [0]);
                  for (var sale in sales) {
                    final transactionId = sale['transaction_id'] != null ? int.tryParse(sale['transaction_id'].toString()) : null;
                    final saleId = sale['id'] != null ? int.tryParse(sale['id'].toString()) : null;
                    if (transactionId != null) {
                      await Sell().delete(transactionId);
                    }
                    if (saleId != null) {
                      await SellDatabase().deleteSell(saleId);
                    }
                  }
                }
                onPaymentCompleted();
                Navigator.of(context).pop();
                Navigator.pop(context);
              } catch (e) {
                _showErrorSnackBar(e.toString());
              }
            },
            child: Text(AppLocalizations.of(context).translate('yes')),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (Platform.isIOS || Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      CustomSnackbarManager.show(context, message, isError: true);
    }
  }

  void _showSuccessSnackBar(String message) {
    if (Platform.isIOS || Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else {
      CustomSnackbarManager.show(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return Scaffold(
      backgroundColor: customAppTheme.bgLayer1,
      appBar: AppBar(
        actionsPadding: EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        elevation: 5,
        title: Row(
          spacing: 10,
          children: [
            SizedBox(
              height: 34,
              width: MediaQuery.sizeOf(context).width * 0.3,
              child: BranchSelector(
                onBranchSelected: onBranchSelected,
                selectedBranchId: selectedBranchId,
              ),
            ),
            SizedBox(
              height: 34,
              width: MediaQuery.sizeOf(context).width * 0.2,
              child: DateTimeSelector(
                onDateSelected: (date) {
                  if (mounted) {
                    setState(() {
                      selectedDate = date;
                    });
                  }
                },
                selectedDate: selectedDate,
              ),
            ),
            SizedBox(
              height: 34,
              width: MediaQuery.sizeOf(context).width * 0.2,
              child: InvoiceTypeSelector(
                onInvoiceTypeSelected: onInvoiceTypeSelected,
                selectedInvoiceType: invoiceType,
                isQuotation: isQuotation,
                isSuspend: isSuspend,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await refreshProducts();
            },
            icon: Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context).translate('refresh_products'),
          ),
          IconButton(
            onPressed: () async {
              bool isFullScreen = await windowManager.isFullScreen();
              if (isFullScreen) {
                await windowManager.setFullScreen(false);
                if (previousSize != null) {
                  await windowManager.setSize(previousSize!);
                }
                if (previousPosition != null) {
                  await windowManager.setPosition(previousPosition!);
                }
              } else {
                previousSize = await windowManager.getSize();
                previousPosition = await windowManager.getPosition();
                await windowManager.setFullScreen(true);
              }
            },
            icon: Icon(Icons.fullscreen_outlined),
          ),
          Visibility(
            visible: true,
            child: ElevatedButton.icon(
              label: Text(AppLocalizations.of(context).translate('add_expenses')),
              icon: Icon(FontAwesomeIcons.moneyBill),
              onPressed: () async {
                await goToExpenses();
              },
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              spacing: 10,
              children: [
                Expanded(
                  child: Card(
                    elevation: 8,
                    child: Column(
                      children: [
                        CustomerSelector(
                          onCustomerSelected: onCustomerSelected,
                          selectedCustomer: selectedCustomer,
                          isBranchSelected: selectedBranchId != null,
                        ),
                        /* Commented out shipping details button to hide it from UI
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              showShipping = !showShipping;
                            });
                          },
                          icon: Icon(showShipping ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                          label: Text(AppLocalizations.of(context).translate('shipping_details')),
                          style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(themeData.colorScheme.primary)),
                        ),
                        */
                        Visibility(
                          visible: showShipping,
                          child: ShippingDetails(
                            onShippingDetailsChanged: onShippingDetailsChanged,
                            shippingCharges: shippingCharges,
                            shippingDetails: shippingDetails,
                            shippingAddress: shippingAddress,
                            shippingStatus: shippingStatus,
                            deliveredTo: deliveredTo,
                          ),
                        ),
                        Expanded(
                          child: CartSummary(
                            cartItems: cartItems,
                            onCartUpdated: onCartUpdated,
                            discountController: discountController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    elevation: 8,
                    child: ProductGrid(
                      branchId: selectedBranchId,
                      onProductAdded: (product) {
                        if (mounted) {
                          setState(() {
                            final existingItem = cartItems.firstWhere(
                                  (item) => item['product_id'] == product['product_id'],
                              orElse: () => null,
                            );
                            if (existingItem != null) {
                              existingItem['quantity'] = (existingItem['quantity'] ?? 0) + 1;
                            } else {
                              product['quantity'] = 1;
                              product['discount_amount'] = 0.0;
                              product['discount_type'] = 'fixed';
                              cartItems.add(product);
                            }
                          });
                        }
                      },
                      isBranchSelected: selectedBranchId != null,
                      cartItems: cartItems,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: customAppTheme.bgLayer4,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        width: double.infinity,
        height: 100,
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '${AppLocalizations.of(context).translate('total_payable')}: ${Helper().formatCurrency(invoiceAmount)} $symbol',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await submitSale();
                },
                label: Text(
                  AppLocalizations.of(context).translate('cash'),
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(FontAwesomeIcons.moneyBill),
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.green)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await submitSale(isCredit: true);
                },
                label: Text(
                  AppLocalizations.of(context).translate('sell_credit'),
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(FontAwesomeIcons.creditCard),
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.orange)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await submitSale(printInvoice: false);
                },
                label: Text(
                  AppLocalizations.of(context).translate('save'),
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(Icons.save),
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blueGrey)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await cancelSale();
                },
                label: Text(
                  AppLocalizations.of(context).translate('cancel'),
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(Icons.cancel_presentation_outlined, color: Colors.white),
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/sale', arguments: 1);
                },
                label: Text(
                  AppLocalizations.of(context).translate('previous_payments'),
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(Icons.history_outlined),
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.purple)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await showMultiPaymentDialog();
                },
                label: Text(
                  AppLocalizations.of(context).translate('multi_payment'),
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(Icons.payment),
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blue)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await showSuspendedSalesDialog();
                },
                label: Text(
                  AppLocalizations.of(context).translate('suspended_sales'),
                  style: TextStyle(color: Colors.white),
                ),
                icon: Icon(Icons.pause_circle_outline),
                style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.teal)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget printInvoiceDialog(BuildContext context, void Function() printDocument) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).translate('print_invoice')),
      content: Text(AppLocalizations.of(context).translate('print_invoice_confirmation')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context).translate('no')),
        ),
        TextButton(
          onPressed: () async {
            printDocument();
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context).translate('yes')),
        ),
      ],
    );
  }
}