import 'package:flashy_tab_bar2/flashy_tab_bar2.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_final/pages/category_screen.dart';
import 'package:pos_final/pages/home.dart';
import 'package:pos_final/pages/sales.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../locale/my_localizations.dart';
import '../models/attendance.dart';
import '../models/payment_database.dart';
import '../models/sell_database.dart';
import '../models/system.dart';
import 'app_theme.dart';
import 'size_config.dart';
import 'icons.dart';
import 'other_helpers.dart';

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  dynamic user,
      note = TextEditingController(),
      clockInTime = DateTime.now(),
      selectedLanguage;
  LatLng? currentLoc;

  String businessSymbol = '',
      businessLogo = '',
      defaultImage = 'assets/images/default_product.png',
      businessName = '',
      userName = '';

  double totalSalesAmount = 0.00,
      totalReceivedAmount = 0.00,
      totalDueAmount = 0.00,
      byCash = 0.00,
      byCard = 0.00,
      byCheque = 0.00,
      byBankTransfer = 0.00,
      byOther = 0.00,
      byCustomPayment_1 = 0.00,
      byCustomPayment_2 = 0.00,
      byCustomPayment_3 = 0.00;

  bool accessExpenses = false,
      attendancePermission = false,
      notPermitted = false,
      syncPressed = false;
  bool? checkedIn;

  Map<String, dynamic>? paymentMethods;
  int? totalSales;
  List<Map> method = [], payments = [];

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  int _selectedIndex = 0;
  List<Widget> pagesIndex = <Widget>[const Home(), const CategoryScreen(), const Sales()];

  @override
  void initState() {
    super.initState();
    getPermission();
    homepageData();
    Helper().syncCallLogs();
  }

  Future<void> checkIOButtonDisplay() async {
    final value = await Attendance().getCheckInTime(Config.userId);
    if (value != null) {
      clockInTime = DateTime.parse(value);
    }

    final activeSubscriptionDetails = await System().get('active-subscription');
    if (activeSubscriptionDetails.isNotEmpty &&
        activeSubscriptionDetails[0].containsKey('package_details')) {
      Map<String, dynamic> packageDetails = activeSubscriptionDetails[0]['package_details'];
      if (packageDetails.containsKey('essentials_module') &&
          packageDetails['essentials_module'].toString() == '1') {
        checkedIn = await Attendance().getAttendanceStatus(Config.userId);
      } else {
        checkedIn = null;
      }
    } else {
      checkedIn = null;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> homepageData() async {
    final prefs = await SharedPreferences.getInstance();
    user = await System().get('loggedInUser');
    userName = ((user['surname'] != null) ? user['surname'] : "") + ' ${user['first_name']}';
    await loadPaymentDetails();
    final value = await Helper().getFormattedBusinessDetails();
    businessSymbol = value['symbol'] ?? '';
    businessLogo = value['logo'] ?? Config().defaultBusinessImage;
    businessName = value['name'] ?? '';
    Config.quantityPrecision = value['quantityPrecision'] ?? 2;
    Config.currencyPrecision = value['currencyPrecision'] ?? 2;
    selectedLanguage = prefs.getString('language_code') ?? Config().defaultLanguage;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pagesIndex.elementAt(_selectedIndex),
      bottomNavigationBar: Builder(
        builder: (BuildContext context) {
          return FlashyTabBar(
            selectedIndex: _selectedIndex,
            showElevation: true,
            onItemSelected: _changePage,
            items: [
              FlashyTabBarItem(
                icon: const Icon(IconBroken.home),
                title: Text(AppLocalizations.of(context)?.translate('home') ?? 'Home'),
              ),
              FlashyTabBarItem(
                icon: const Icon(IconBroken.category),
                title: Text(AppLocalizations.of(context)?.translate('Categories') ?? 'Categories'),
              ),
              FlashyTabBarItem(
                icon: const Icon(IconBroken.chart),
                title: Text(AppLocalizations.of(context)?.translate('sales') ?? 'Sales'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _changePage(int value) {
    setState(() {
      _selectedIndex = value;
    });
  }

  Widget paymentDetails() {
    return Container(
      padding: EdgeInsets.all(MySize.size8!),
      margin: EdgeInsets.all(MySize.size16!),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
        color: customAppTheme.bgLayer1,
        border: Border.all(color: customAppTheme.bgLayer4, width: 1.2),
      ),
      child: Column(
        children: <Widget>[
          Text(
            AppLocalizations.of(context)?.translate('payment_details') ?? 'Payment Details',
            style: AppTheme.getTextStyle(
              themeData.textTheme.titleMedium,
              fontWeight: 700,
              letterSpacing: -0.2,
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(10),
            itemCount: method.length,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              height: 30,
                              width: 2,
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha((0.5 * 256).toInt()),
                                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                              ),
                            ),
                            const Padding(padding: EdgeInsets.symmetric(horizontal: 2)),
                            Text(method[index]['key'] ?? ''),
                          ],
                        ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Text('$businessSymbol ${Helper().formatCurrency(method[index]['value'] ?? 0.0)}'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> getPermission() async {
    List<PermissionStatus> status = [
      await Permission.location.status,
      await Permission.storage.status,
      await Permission.camera.status,
    ];
    notPermitted = status.contains(PermissionStatus.denied);
    final hasAttendancePermission = await Helper().getPermission('essentials.allow_users_for_attendance_from_api');
    if (hasAttendancePermission) {
      await checkIOButtonDisplay();
      if (mounted) {
        setState(() {
          attendancePermission = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          checkedIn = null;
        });
      }
    }

    if (await Helper().getPermission('all_expense.access') ||
        await Helper().getPermission('view_own_expense')) {
      if (mounted) {
        setState(() {
          accessExpenses = true;
        });
      }
    }
  }

  Widget checkIO() {
    if (checkedIn != null) {
      return Padding(
        padding: EdgeInsets.only(top: MySize.size10!),
        child: Column(
          children: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: (!checkedIn!)
                    ? themeData.colorScheme.primary
                    : themeData.colorScheme.surface,
              ),
              onPressed: () async {
                Helper().syncCallLogs();
                showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        (!checkedIn!)
                            ? AppLocalizations.of(context)?.translate('check_in_note') ?? 'Check-in Note'
                            : AppLocalizations.of(context)?.translate('check_out_note') ?? 'Check-out Note',
                        textAlign: TextAlign.center,
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.titleLarge,
                          color: themeData.colorScheme.onSurface,
                          fontWeight: 600,
                          muted: true,
                        ),
                      ),
                      content: TextFormField(
                        controller: note,
                        autofocus: true,
                        style: AppTheme.getTextStyle(
                          themeData.textTheme.bodyLarge,
                          color: themeData.colorScheme.onSurface,
                          fontWeight: 600,
                          muted: true,
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: themeData.colorScheme.primary,
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            if (await Helper().checkConnectivity()) {
                              try {
                                final position = await Geolocator.getCurrentPosition(
                                  locationSettings: const LocationSettings(
                                    accuracy: LocationAccuracy.high,
                                  ),
                                );
                                currentLoc = LatLng(position.latitude, position.longitude);
                              } catch (_) {}

                              if (checkedIn == false) {
                                final ipAddress = IpAddress(type: RequestType.json);
                                final data = await ipAddress.getIpAddress();
                                final iP = data.toString();

                                final checkInMap = await Attendance().doCheckIn(
                                  checkInNote: note.text,
                                  iPAddress: iP,
                                  latitude: currentLoc?.latitude.toString() ?? '',
                                  longitude: currentLoc?.longitude.toString() ?? '',
                                );
                                Fluttertoast.showToast(msg: checkInMap.toString());
                                note.clear();
                              } else {
                                final checkOutMap = await Attendance().doCheckOut(
                                  latitude: currentLoc?.latitude.toString() ?? '',
                                  longitude: currentLoc?.longitude.toString() ?? '',
                                  checkOutNote: note.text,
                                );
                                Fluttertoast.showToast(msg: checkOutMap.toString());
                                note.clear();
                              }
                              checkedIn = await Attendance().getAttendanceStatus(Config.userId);
                              final checkInTimeValue = await Attendance().getCheckInTime(Config.userId);
                              if (checkInTimeValue != null) {
                                clockInTime = DateTime.parse(checkInTimeValue);
                              }
                              if (mounted) {
                                setState(() {});
                              }
                            } else {
                              Fluttertoast.showToast(
                                msg: AppLocalizations.of(context)?.translate('check_connectivity') ?? 'Check Connectivity',
                              );
                            }
                          },
                          child: Text(AppLocalizations.of(context)?.translate('ok') ?? 'OK'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(AppLocalizations.of(context)?.translate('cancel') ?? 'Cancel'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: (!checkedIn!)
                  ? Text(
                AppLocalizations.of(context)?.translate('check_in') ?? 'Check In',
                style: AppTheme.getTextStyle(
                  themeData.textTheme.titleLarge,
                  color: themeData.colorScheme.surface,
                  fontWeight: 600,
                ),
              )
                  : Text(
                AppLocalizations.of(context)?.translate('check_out') ?? 'Check Out',
                style: AppTheme.getTextStyle(
                  themeData.textTheme.titleLarge,
                  color: themeData.colorScheme.primary,
                  fontWeight: 600,
                ),
              ),
            ),
            Text(
              (!checkedIn!) ? '' : DateTime.now().difference(clockInTime).toString(),
              style: AppTheme.getTextStyle(
                themeData.textTheme.titleSmall,
                color: themeData.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }

  Future<List> loadStatistics() async {
    final result = await SellDatabase().getSells();
    totalSales = result.length;
    totalSalesAmount = 0.0;
    totalReceivedAmount = 0.0;
    totalDueAmount = 0.0;
    payments.clear();

    for (var sell in result) {
      final payment = await PaymentDatabase().get(sell['id'], allColumns: true);
      double paidAmount = 0.0;
      double returnAmount = 0.0;
      for (dynamic element in payment) {
        if (element['is_return'] == 0) {
          paidAmount += element['amount'] ?? 0.0;
          payments.add({'key': element['method'], 'value': element['amount']});
        } else {
          returnAmount += element['amount'] ?? 0.0;
        }
      }
      totalSalesAmount += sell['invoice_amount'] ?? 0.0;
      totalReceivedAmount += (paidAmount - returnAmount);
      totalDueAmount += sell['pending_amount'] ?? 0.0;
    }

    if (mounted) {
      setState(() {});
    }
    return result;
  }

  Future<void> loadPaymentDetails() async {
    List<Map<String, dynamic>> paymentMethod = [];
    await System().get('payment_methods').then((value) {
      value.forEach((element) {
        element.forEach((k, v) {
          paymentMethod.add({'key': '$k', 'value': '$v'});
        });
      });
    });

    byCash = 0.0;
    byCard = 0.0;
    byCheque = 0.0;
    byBankTransfer = 0.0;
    byOther = 0.0;
    byCustomPayment_1 = 0.0;
    byCustomPayment_2 = 0.0;
    byCustomPayment_3 = 0.0;
    method.clear();

    await loadStatistics();

    for (dynamic row in payments) {
      if (row['key'] == 'cash') {
        byCash += row['value'] ?? 0.0;
      } else if (row['key'] == 'card') {
        byCard += row['value'] ?? 0.0;
      } else if (row['key'] == 'cheque') {
        byCheque += row['value'] ?? 0.0;
      } else if (row['key'] == 'bank_transfer') {
        byBankTransfer += row['value'] ?? 0.0;
      } else if (row['key'] == 'other') {
        byOther += row['value'] ?? 0.0;
      } else if (row['key'] == 'custom_pay_1') {
        byCustomPayment_1 += row['value'] ?? 0.0;
      } else if (row['key'] == 'custom_pay_2') {
        byCustomPayment_2 += row['value'] ?? 0.0;
      } else if (row['key'] == 'custom_pay_3') {
        byCustomPayment_3 += row['value'] ?? 0.0;
      }
    }

    for (dynamic row in paymentMethod) {
      if (byCash > 0 && row['key'] == 'cash') {
        method.add({'key': row['value'], 'value': byCash});
      }
      if (byCard > 0 && row['key'] == 'card') {
        method.add({'key': row['value'], 'value': byCard});
      }
      if (byCheque > 0 && row['key'] == 'cheque') {
        method.add({'key': row['value'], 'value': byCheque});
      }
      if (byBankTransfer > 0 && row['key'] == 'bank_transfer') {
        method.add({'key': row['value'], 'value': byBankTransfer});
      }
      if (byOther > 0 && row['key'] == 'other') {
        method.add({'key': row['value'], 'value': byOther});
      }
      if (byCustomPayment_1 > 0 && row['key'] == 'custom_pay_1') {
        method.add({'key': row['value'], 'value': byCustomPayment_1});
      }
      if (byCustomPayment_2 > 0 && row['key'] == 'custom_pay_2') {
        method.add({'key': row['value'], 'value': byCustomPayment_2});
      }
      if (byCustomPayment_3 > 0 && row['key'] == 'custom_pay_3') {
        method.add({'key': row['value'], 'value': byCustomPayment_3});
      }
    }

    if (mounted) {
      setState(() {});
    }
  }
}