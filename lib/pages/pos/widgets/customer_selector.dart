import 'package:flutter/material.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/contact.dart' as contact_lib;
import 'package:pos_final/apis/contact.dart'; // أضفت هذا الاستيراد لـ CustomerApi
import 'package:pos_final/helpers/other_helpers.dart'; // أضفت هذا الاستيراد لـ Helper

class CustomerSelector extends StatefulWidget {
  final Function(Map<String, dynamic>?) onCustomerSelected;
  final Map<String, dynamic>? selectedCustomer;
  final bool isBranchSelected;

  const CustomerSelector({
    super.key,
    required this.onCustomerSelected,
    this.selectedCustomer,
    required this.isBranchSelected,
  });

  @override
  CustomerSelectorState createState() => CustomerSelectorState();
}

class CustomerSelectorState extends State<CustomerSelector> {
  List<Map<String, dynamic>> customerList = [
    {'id': 0, 'name': 'Select Customer', 'mobile': ' - '}
  ];
  Map<String, dynamic>? selectedCustomer;
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  void initState() {
    super.initState();
    selectedCustomer = widget.selectedCustomer;
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isLoading = true;
    });

    try {
      // تحقق إذا كانت البيانات بحاجة إلى تحديث
      if (await Helper().needsCustomersRefresh()) {
        await CustomerApi().get();
      }

      contact_lib.Contact contact = contact_lib.Contact();
      List customers = await contact.get();
      if (mounted) {
        setState(() {
          customerList.clear();
          customerList.add({'id': 0, 'name': 'Select Customer', 'mobile': ' - '});
          for (var value in customers) {
            if (value['id'] != null && value['name'] != null) {
              customerList.add({
                'id': value['id'] as int,
                'name': value['name'] as String,
                'mobile': (value['mobile'] ?? ' - ') as String,
              });
            }
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddCustomerDialog(
          onCustomerAdded: (newCustomer) {
            setState(() {
              customerList.add(newCustomer);
              selectedCustomer = newCustomer;
              widget.onCustomerSelected(newCustomer);
            });
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    if (isLoading) {
      return Container(
        padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: (MySize.size8 ?? 8.0).toDouble()),
      padding: EdgeInsets.all((MySize.size8 ?? 8.0).toDouble()),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((MySize.size12 ?? 12.0).toDouble()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                size: (MySize.size24 ?? 24.0).toDouble(),
                color: themeData.colorScheme.primary,
              ),
              SizedBox(width: (MySize.size12 ?? 12.0).toDouble()),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).translate('select_customer'),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size16 ?? 16.0).toDouble(),
                    fontWeight: FontWeight.w600,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.person_add,
                  size: (MySize.size24 ?? 24.0).toDouble(),
                  color: themeData.colorScheme.primary,
                ),
                onPressed: widget.isBranchSelected ? _showAddCustomerDialog : null,
              ),
            ],
          ),
          SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
          SearchAnchor(
            builder: (BuildContext context, SearchController controller) {
              return TextField(
                controller: _searchController,
                enabled: widget.isBranchSelected,
                decoration: InputDecoration(
                  hintText: selectedCustomer != null && selectedCustomer!['id'] != 0
                      ? '${selectedCustomer!['name']} (${selectedCustomer!['mobile']})'
                      : AppLocalizations.of(context).translate('select_customer'),
                  hintStyle: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: (MySize.size14 ?? 14.0).toDouble(),
                    color: themeData.colorScheme.onSurface.withAlpha(150),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: themeData.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: customAppTheme.bgLayer2,
                ),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  color: themeData.colorScheme.onSurface,
                ),
                onTap: () {
                  controller.openView();
                },
              );
            },
            suggestionsBuilder: (BuildContext context, SearchController controller) {
              final keyword = controller.value.text.toLowerCase();
              return customerList.where((customer) {
                return customer['id'] != 0 && // استثناء العميل الافتراضي
                    (customer['name'].toLowerCase().contains(keyword) ||
                        customer['mobile'].toLowerCase().contains(keyword));
              }).map((customer) {
                return ListTile(
                  title: Text(
                    customer['name'],
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: (MySize.size14 ?? 14.0).toDouble(),
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    customer['mobile'],
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: (MySize.size12 ?? 12.0).toDouble(),
                      color: themeData.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      selectedCustomer = customer;
                      widget.onCustomerSelected(customer);
                      _searchController.text =
                      '${customer['name']} (${customer['mobile']})';
                      controller.closeView(null);
                    });
                  },
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }
}

class AddCustomerDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onCustomerAdded;

  const AddCustomerDialog({super.key, required this.onCustomerAdded});

  @override
  AddCustomerDialogState createState() => AddCustomerDialogState();
}

class AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstName = TextEditingController();
  final TextEditingController mobile = TextEditingController();
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);

  @override
  void dispose() {
    firstName.dispose();
    mobile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        AppLocalizations.of(context).translate('create_contact'),
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: (MySize.size18 ?? 18.0).toDouble(),
          fontWeight: FontWeight.w600,
          color: themeData.colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: firstName,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('first_name'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  color: themeData.colorScheme.onSurface,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).translate('please_enter_first_name');
                  }
                  return null;
                },
              ),
              SizedBox(height: (MySize.size12 ?? 12.0).toDouble()),
              TextFormField(
                controller: mobile,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('phone'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
                  ),
                ),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  color: themeData.colorScheme.onSurface,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).translate('please_enter_contact_number');
                  }
                  return null;
                },
              ),
            ],
          ),
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
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final newCustomer = {
                'id': DateTime.now().millisecondsSinceEpoch,
                'name': firstName.text,
                'mobile': mobile.text,
              };
              contact_lib.Contact contact = contact_lib.Contact();
              await contact.insertContact({
                'id': newCustomer['id'],
                'name': newCustomer['name'],
                'mobile': newCustomer['mobile'],
              } as contact_lib.ContactModel);
              widget.onCustomerAdded(newCustomer);
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.primary,
          ),
          child: Text(
            AppLocalizations.of(context).translate('add_to_contact'),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: (MySize.size14 ?? 14.0).toDouble(),
              color: themeData.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}