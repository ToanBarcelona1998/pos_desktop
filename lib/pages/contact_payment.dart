
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../apis/contact_payment.dart';
import '../helpers/app_theme.dart';
import '../helpers/size_config.dart';
import '../helpers/other_helpers.dart';
import '../locale/my_localizations.dart';
import '../models/contact_model.dart';
import '../models/system.dart';

class ContactPayment extends StatefulWidget {
  const ContactPayment({super.key});

  @override
  ContactPaymentState createState() => ContactPaymentState();
}

class ContactPaymentState extends State<ContactPayment> {
  final _formKey = GlobalKey<FormState>();
  int selectedCustomerId = 0;
  List<Map<String, dynamic>> customerListMap = [],
      paymentAccounts = [],
      paymentMethods = [],
      locationListMap = [
        {'id': 0, 'name': 'Set Location'}
      ];
  Map<String, dynamic> selectedLocation = {'id': 0, 'name': 'Set Location'},
      selectedCustomer = {'id': 0, 'name': 'Select Customer', 'mobile': ' - '};
  String due = '0.00';
  Map<String, dynamic> selectedPaymentAccount = {'id': null, 'name': "None"},
      selectedPaymentMethod = {
        'name': 'name',
        'value': 'value',
        'account_id': null
      };

  String symbol = '';
  var payingAmount = TextEditingController();

  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    selectCustomer();
    setPaymentDetails();
    setLocationMap();
    Helper().syncCallLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text(
          AppLocalizations.of(context).translate('contact_payment'),
          style: AppTheme.getTextStyle(
            themeData.textTheme.headlineSmall,
            fontWeight: 700,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(MySize.size24!),
        child: Form(
          key: _formKey,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Customer Selection and Due Amount
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MySize.size12!),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(MySize.size16!),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate('select_customer'),
                          style: AppTheme.getTextStyle(
                            themeData.textTheme.titleLarge,
                            fontWeight: 700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: MySize.size16!),
                        customerList(),
                        SizedBox(height: MySize.size24!),
                        Center(
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('due')
                                    .toUpperCase(),
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.titleMedium,
                                  fontWeight: 600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: MySize.size8!),
                              Text(
                                Helper().formatCurrency(due),
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.headlineMedium,
                                  fontWeight: 700,
                                  letterSpacing: -0.2,
                                  color: themeData.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: MySize.size24!),
              // Right Column: Payment Details and Submit
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MySize.size12!),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(MySize.size16!),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Visibility(
                          visible: selectedCustomerId != 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .translate('payment_details'),
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.titleLarge,
                                  fontWeight: 700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              SizedBox(height: MySize.size16!),
                              TextFormField(
                                decoration: InputDecoration(
                                  prefix: Text(symbol),
                                  labelText: AppLocalizations.of(context)
                                      .translate('payment_amount'),
                                  border:
                                  themeData.inputDecorationTheme.border,
                                  enabledBorder:
                                  themeData.inputDecorationTheme.border,
                                  focusedBorder: themeData
                                      .inputDecorationTheme.focusedBorder,
                                  filled: true,
                                  fillColor: customAppTheme.bgLayer1,
                                ),
                                controller: payingAmount,
                                validator: (newValue) {
                                  if ((newValue == '' ||
                                      double.parse(newValue!) < 0.01) ||
                                      double.parse(newValue) >
                                          double.parse(due.toString())) {
                                    return AppLocalizations.of(context)
                                        .translate('enter_valid_payment_amount');
                                  }
                                  return null;
                                },
                                textAlign: TextAlign.end,
                                style: AppTheme.getTextStyle(
                                  themeData.textTheme.titleMedium,
                                  fontWeight: 500,
                                  letterSpacing: -0.2,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter(
                                    RegExp(r'^(\d+)?\.?\d{0,2}'),
                                    allow: true,
                                  ),
                                ],
                                keyboardType: TextInputType.number,
                              ),
                              SizedBox(height: MySize.size16!),
                              Row(
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context).translate('location')} : ',
                                    style: AppTheme.getTextStyle(
                                      themeData.textTheme.titleLarge,
                                      fontWeight: 700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  locations(),
                                ],
                              ),
                              SizedBox(height: MySize.size16!),
                              Row(
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context).translate('payment_method')} : ',
                                    style: AppTheme.getTextStyle(
                                      themeData.textTheme.titleLarge,
                                      fontWeight: 700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  paymentOptions(),
                                ],
                              ),
                              SizedBox(height: MySize.size16!),
                              Row(
                                children: [
                                  Text(
                                    '${AppLocalizations.of(context).translate('payment_account')} : ',
                                    style: AppTheme.getTextStyle(
                                      themeData.textTheme.titleLarge,
                                      fontWeight: 700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  paymentAccount(),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: MySize.size24!),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeData.colorScheme.primary,
                              padding: EdgeInsets.symmetric(
                                horizontal: MySize.size32!,
                                vertical: MySize.size16!,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(MySize.size8!),
                              ),
                            ),
                            onPressed: () async {
                              await onSubmit();
                            },
                            child: Text(
                              AppLocalizations.of(context).translate('submit'),
                              style: AppTheme.getTextStyle(
                                themeData.textTheme.titleLarge,
                                color: themeData.colorScheme.onPrimary,
                                fontWeight: 700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  onSubmit() async {
    if (await Helper().checkConnectivity()) {
      if (_formKey.currentState!.validate()) {
        if (selectedLocation['id'] != 0) {
          Map<String, dynamic> paymentMap = {
            "contact_id": selectedCustomerId,
            "amount": double.parse(payingAmount.text),
            "method": selectedPaymentMethod['name'],
            "account_id": selectedPaymentMethod['account_id'],
            "paid_on": DateFormat("yyyy-MM-dd hh:mm:ss")
                .format(DateTime.now())
                .toString(),
          };
          await ContactPaymentApi()
              .postContactPayment(paymentMap)
              .then((value) {
            Navigator.popUntil(context, ModalRoute.withName('/layout'));
            Fluttertoast.showToast(
              backgroundColor: Colors.green,
              msg: AppLocalizations.of(context).translate('payment_successful'),
            );
            Navigator.pushNamed(context, '/layout');
          });
        } else {
          Fluttertoast.showToast(
            msg: AppLocalizations.of(context).translate('error_invalid_location'),
          );
        }
      }
    } else {
      Fluttertoast.showToast(
        msg: AppLocalizations.of(context).translate('check_connectivity'),
      );
    }
  }

  Widget customerList() {
    String barHint =
        '${selectedCustomer['name']} (${selectedCustomer['mobile'] ?? ' - '})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchAnchor(
          builder: (BuildContext context, SearchController controller) {
            return TextFormField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('select_customer'),
                hintText: barHint,
                border: themeData.inputDecorationTheme.border,
                enabledBorder: themeData.inputDecorationTheme.border,
                focusedBorder: themeData.inputDecorationTheme.focusedBorder,
                filled: true,
                fillColor: customAppTheme.bgLayer1,
                suffixIcon: Icon(MdiIcons.chevronDown),
              ),
              onTap: () {
                controller.openView();
              },
            );
          },
          suggestionsBuilder: (BuildContext context, SearchController controller) {
            final keyword = controller.value.text;
            return customerListMap
                .where((element) =>
            element['name']
                .toString()
                .toLowerCase()
                .contains(keyword.toLowerCase()) ||
                (element['mobile'] ?? '')
                    .toString()
                    .contains(keyword))
                .map((element) => CustomerData(
              name: element['name'],
              mobileNumber: element['mobile'] ?? '-',
              themeData: themeData,
              onTap: () async {
                controller.clear();
                selectedCustomer = element;
                var newValue = selectedCustomer['id'];
                if (newValue != 0) {
                  if (await Helper().checkConnectivity()) {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          content: Row(
                            children: [
                              const CircularProgressIndicator(),
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: Text(
                                  AppLocalizations.of(context)
                                      .translate('loading'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                    await ContactPaymentApi()
                        .getCustomerDue(newValue)
                        .then((value) {
                      if (value != null) {
                        due = value['data'][0]['sell_due'].toString();
                        setState(() {
                          selectedCustomerId = newValue;
                          _formKey.currentState!.reset();
                        });
                      }
                      Navigator.pop(context);
                    });
                  } else {
                    Fluttertoast.showToast(
                      msg: AppLocalizations.of(context)
                          .translate('check_connectivity'),
                    );
                  }
                }
                controller.closeView(null);
              },
            ))
                .toList();
          },
        ),
      ],
    );
  }

  Widget locations() {
    return PopupMenuButton<Map<String, dynamic>>(
      onSelected: (item) {
        setState(() {
          selectedLocation = item;
          setPaymentDetails().then((value) {
            selectedPaymentMethod = paymentMethods[0];
            selectedPaymentAccount = paymentAccounts[0];
            for (var element in paymentAccounts) {
              if (selectedPaymentMethod['account_id'] == element['id']) {
                selectedPaymentAccount = element;
              }
            }
          });
        });
      },
      itemBuilder: (BuildContext context) {
        return locationListMap.map((Map<String, dynamic> value) {
          return PopupMenuItem<Map<String, dynamic>>(
            value: value,
            height: MySize.size36!,
            child: Text(
              value['name'],
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyMedium,
                color: themeData.colorScheme.onSurface,
              ),
            ),
          );
        }).toList();
      },
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.only(
          left: MySize.size12!,
          right: MySize.size12!,
          top: MySize.size8!,
          bottom: MySize.size8!,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
          color: customAppTheme.bgLayer1,
          border: Border.all(color: customAppTheme.bgLayer3, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Text(
              selectedLocation['name'],
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyLarge,
                color: themeData.colorScheme.onSurface,
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: MySize.size4!),
              child: Icon(
                MdiIcons.chevronDown,
                size: MySize.size22,
                color: themeData.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentOptions() {
    return PopupMenuButton<Map<String, dynamic>>(
      onSelected: (item) {
        setState(() {
          selectedPaymentMethod = item;
          selectedPaymentAccount = paymentAccounts[0];
          for (var element in paymentAccounts) {
            if (selectedPaymentMethod['account_id'] == element['id']) {
              selectedPaymentAccount = element;
            }
          }
        });
      },
      itemBuilder: (BuildContext context) {
        return paymentMethods.map((Map<String, dynamic> value) {
          return PopupMenuItem<Map<String, dynamic>>(
            value: value,
            height: MySize.size36!,
            child: Text(
              value['value'],
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyMedium,
                color: themeData.colorScheme.onSurface,
              ),
            ),
          );
        }).toList();
      },
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.only(
          left: MySize.size12!,
          right: MySize.size12!,
          top: MySize.size8!,
          bottom: MySize.size8!,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
          color: customAppTheme.bgLayer1,
          border: Border.all(color: customAppTheme.bgLayer3, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Text(
              selectedPaymentMethod['value'],
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyLarge,
                color: themeData.colorScheme.onSurface,
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: MySize.size4!),
              child: Icon(
                MdiIcons.chevronDown,
                size: MySize.size22,
                color: themeData.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentAccount() {
    return PopupMenuButton<Map<String, dynamic>>(
      onSelected: (item) {
        setState(() {
          selectedPaymentAccount = item;
          selectedPaymentMethod['account_id'] = item['id'];
        });
      },
      itemBuilder: (BuildContext context) {
        return paymentAccounts.map((Map<String, dynamic> value) {
          return PopupMenuItem<Map<String, dynamic>>(
            value: value,
            height: MySize.size36!,
            child: Text(
              value['name'],
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyMedium,
                color: themeData.colorScheme.onSurface,
              ),
            ),
          );
        }).toList();
      },
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.only(
          left: MySize.size12!,
          right: MySize.size12!,
          top: MySize.size8!,
          bottom: MySize.size8!,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(MySize.size8!)),
          color: customAppTheme.bgLayer1,
          border: Border.all(color: customAppTheme.bgLayer3, width: 1),
        ),
        child: Row(
          children: <Widget>[
            Text(
              selectedPaymentAccount['name'],
              style: AppTheme.getTextStyle(
                themeData.textTheme.bodyLarge,
                color: themeData.colorScheme.onSurface,
              ),
            ),
            Container(
              margin: EdgeInsets.only(left: MySize.size4!),
              child: Icon(
                MdiIcons.chevronDown,
                size: MySize.size22,
                color: themeData.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  selectCustomer() async {
    customerListMap = [
      {'id': 0, 'name': 'Select Customer', 'mobile': ' - '}
    ];
    await Contact().get().then((value) {
      for (var element in value) {
        setState(() {
          customerListMap.add({
            'id': element['id'],
            'name': element['name'],
            'mobile': element['mobile']
          });
        });
      }
    });
  }

  setLocationMap() async {
    locationListMap = [];
    await System().get('location').then((value) {
      value.forEach((element) {
        setState(() {
          locationListMap.add({
            'id': element['id'],
            'name': element['name'],
          });
        });
      });
    });
  }

  setPaymentDetails() async {
    await Helper().getFormattedBusinessDetails().then((value) {
      setState(() {
        symbol = value['symbol'];
      });
    });
    List payments =
    await System().get('payment_method', selectedLocation['id']);
    paymentAccounts = [
      {'id': null, 'name': "None"}
    ];
    await System().getPaymentAccounts().then((value) {
      List<String> accIds = [];
      for (var element in value) {
        for (var payment in payments) {
          if ((payment['account_id'].toString() == element['id'].toString()) &&
              !accIds.contains(element['id'].toString())) {
            accIds.add(element['id'].toString());
            paymentAccounts.add({'id': element['id'], 'name': element['name']});
          }
        }
      }
    });
    paymentMethods = [];
    for (var element in payments) {
      setState(() {
        paymentMethods.add({
          'name': element['name'],
          'value': element['label'],
          'account_id': (element['account_id'] != null)
              ? int.parse(element['account_id'].toString())
              : null
        });
      });
    }
  }
}

class CustomerData extends StatelessWidget {
  const CustomerData({
    super.key,
    required this.name,
    required this.mobileNumber,
    required this.themeData,
    this.onTap,
  });

  final String name, mobileNumber;
  final ThemeData themeData;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: MySize.size4!),
      child: ListTile(
        onTap: onTap,
        title: Text(
          name,
          style: AppTheme.getTextStyle(
            themeData.textTheme.bodyLarge,
            color: themeData.colorScheme.onSurface,
            fontWeight: 500,
          ),
        ),
        trailing: Text(
          '($mobileNumber)',
          style: AppTheme.getTextStyle(
            themeData.textTheme.bodyLarge,
            color: themeData.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}