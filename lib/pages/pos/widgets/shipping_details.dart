import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/shipment.dart';

class ShippingDetails extends StatefulWidget {
  final Function(Map<String, dynamic>) onShippingDetailsChanged;
  final double? shippingCharges;
  final String? shippingDetails;
  final String? shippingAddress;
  final String? shippingStatus;
  final String? deliveredTo;

  const ShippingDetails({
    super.key,
    required this.onShippingDetailsChanged,
    this.shippingCharges,
    this.shippingDetails,
    this.shippingAddress,
    this.shippingStatus,
    this.deliveredTo,
  });

  @override
  ShippingDetailsState createState() => ShippingDetailsState();
}

class ShippingDetailsState extends State<ShippingDetails> {
  final TextEditingController _shippingChargesController = TextEditingController();
  final TextEditingController _shippingDetailsController = TextEditingController();
  final TextEditingController _shippingAddressController = TextEditingController();
  final TextEditingController _deliveredToController = TextEditingController();
  String? _selectedShippingStatus;
  String _symbol = '';
  static int themeType = 1;
  ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);
  final ShipmentModel _shipmentModel = ShipmentModel();

  @override
  void initState() {
    super.initState();
    _initializeData();
    _shippingChargesController.text = widget.shippingCharges?.toStringAsFixed(2) ?? '0.00';
    _shippingDetailsController.text = widget.shippingDetails ?? '';
    _shippingAddressController.text = widget.shippingAddress ?? '';
    _deliveredToController.text = widget.deliveredTo ?? '';
    _selectedShippingStatus = widget.shippingStatus ?? _shipmentModel.shipmentStatus.first;
    _shippingChargesController.addListener(_updateShippingDetails);
    _shippingDetailsController.addListener(_updateShippingDetails);
    _shippingAddressController.addListener(_updateShippingDetails);
    _deliveredToController.addListener(_updateShippingDetails);
  }

  Future<void> _initializeData() async {
    final value = await Helper().getFormattedBusinessDetails();
    if (mounted) {
      setState(() {
        _symbol = value['symbol'] != null ? value['symbol'] + ' ' : '';
      });
    }
  }

  void _updateShippingDetails() {
    final shippingData = {
      'shipping_charges': double.tryParse(_shippingChargesController.text) ?? 0.0,
      'shipping_details': _shippingDetailsController.text,
      'shipping_address': _shippingAddressController.text,
      'shipping_status': _selectedShippingStatus,
      'delivered_to': _deliveredToController.text,
    };
    widget.onShippingDetailsChanged(shippingData);
  }

  @override
  void dispose() {
    _shippingChargesController.dispose();
    _shippingDetailsController.dispose();
    _shippingAddressController.dispose();
    _deliveredToController.dispose();
    super.dispose();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('shipping_details'),
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: (MySize.size16 ?? 16.0).toDouble(),
              fontWeight: FontWeight.w600,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
          TextFormField(
            controller: _shippingChargesController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('shipping_charges'),
              prefixText: _symbol,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular((MySize.size8 ?? 8.0).toDouble()),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^(\d+)?\.?\d{0,2}')),
            ],
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: (MySize.size14 ?? 14.0).toDouble(),
            ),
          ),
          SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
          TextFormField(
            controller: _shippingDetailsController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('shipping_details'),
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
            controller: _shippingAddressController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('shipping_address'),
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
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedShippingStatus,
              hint: Text(
                AppLocalizations.of(context).translate('select_shipping_status'),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: (MySize.size14 ?? 14.0).toDouble(),
                  color: themeData.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              items: _shipmentModel.shipmentStatus.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(
                    AppLocalizations.of(context).translate(status.toLowerCase()),
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: (MySize.size14 ?? 14.0).toDouble(),
                      color: themeData.colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedShippingStatus = newValue;
                  _updateShippingDetails();
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
          SizedBox(height: (MySize.size8 ?? 8.0).toDouble()),
          TextFormField(
            controller: _deliveredToController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('delivered_to'),
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
    );
  }
}