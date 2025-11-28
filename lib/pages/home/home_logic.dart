import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_ip_address/get_ip_address.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_final/api_end_points.dart';
import 'package:pos_final/apis/system.dart';
import 'package:pos_final/config.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/other_helpers.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/attendance.dart';
import 'package:pos_final/models/payment_database.dart';
import 'package:pos_final/models/sell.dart';
import 'package:pos_final/models/sell_database.dart';
import 'package:pos_final/models/system.dart';
import 'package:pos_final/models/variations.dart';
import 'package:pos_final/pages/home.dart';
import 'package:pos_final/pages/report.dart';
import 'package:pos_final/pages/pos/pos_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';

class HomeLogic {
  final HomeState _state;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Animation<double> get fadeAnimation => _fadeAnimation;
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  dynamic user;
  final TextEditingController note = TextEditingController();
  DateTime clockInTime = DateTime.now();
  String? selectedLanguage;
  LatLng? currentLoc;

  String businessSymbol = '';
  String businessLogo = '';
  String businessName = '';
  String userName = '';

  double totalSalesAmount = 0.0;
  double netAmount = 0.0;
  double invoiceDue = 0.0;
  double totalSellReturn = 0.0;
  double totalPurchase = 0.0;
  double purchaseDue = 0.0;
  double totalPurchaseReturn = 0.0;
  double totalExpense = 0.0;

  double byCash = 0.0;
  double byCard = 0.0;
  double byCheque = 0.0;
  double byBankTransfer = 0.0;
  double byOther = 0.0;
  double byCustomPayment_1 = 0.0;
  double byCustomPayment_2 = 0.0;
  double byCustomPayment_3 = 0.0;

  bool accessExpenses = false;
  bool attendancePermission = false;
  bool notPermitted = false;
  bool syncPressed = false;
  bool? checkedIn;

  Map<String, dynamic>? paymentMethods;
  int? totalSales;
  List<Map<String, dynamic>> method = [];
  List<Map<String, dynamic>> payments = [];
  ThemeData themeData = AppTheme.getThemeFromThemeMode(1);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(1);

  IconData get syncIcon => MdiIcons.send;
  IconData get logoutIcon => FontAwesomeIcons.rightFromBracket;
  IconData get menuIcon => FontAwesomeIcons.bars;

  Map<String, dynamic> dashboardData = {};
  List<Map<String, dynamic>> stockAlerts = [];
  List<Map<String, dynamic>> purchaseDues = [];
  List<Map<String, dynamic>> salesDues = [];

  List<Map<String, dynamic>> businessLocations = [];
  int? selectedLocationId;

  String selectedPeriod = 'today'; // Default period is 'today'

  final Logger _logger = Logger('HomeLogic');

  HomeLogic(this._state) {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    });
  }

  String getTranslatedText(BuildContext context, String key) {
    final translation = AppLocalizations.of(context)?.translate(key) ?? key;
    if (translation == key) {
      _logger.warning('Translation missing for key: $key');
    }
    return translation;
  }

  void initState() {
    _animationController = AnimationController(
      vsync: _state,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    getPermission();
    homepageData();
    Helper().syncCallLogs();
  }

  void dispose() {
    _animationController.dispose();
    note.dispose();
  }

  Future<void> homepageData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      user = await System().get('loggedInUser');
      userName = ((user['surname'] != null) ? user['surname'] : '') + ' ${user['first_name'] ?? ''}';
      await loadPaymentDetails();
      await Helper().getFormattedBusinessDetails().then((value) {
        businessSymbol = value['symbol'] ?? '';
        businessLogo = value['logo'] ?? Config().defaultBusinessImage;
        businessName = value['name'] ?? '';
        Config.quantityPrecision = value['quantityPrecision'] ?? 2;
        Config.currencyPrecision = value['currencyPrecision'] ?? 2;
      });
      selectedLanguage = prefs.getString('language_code') ?? Config().defaultLanguage;
      selectedPeriod = 'today';

      await _loadCachedData(prefs);
      await fetchBusinessLocations();
      await refreshData(_state.context);

      await _cacheData(prefs);

      if (_state.mounted) _state.setState(() {});
    } catch (e) {
      _logger.severe('Error in homepageData: $e');
      ScaffoldMessenger.of(_state.context).showSnackBar(
        SnackBar(content: Text(getTranslatedText(_state.context, 'error_loading_data'))),
      );
    }
  }

  Future<void> fetchBusinessLocations() async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _logger.warning('No token available for fetchBusinessLocations');
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/business-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] ?? [];
        businessLocations = List<Map<String, dynamic>>.from(data.map((loc) => {
          'id': loc['id'],
          'name': loc['name'],
        }));
        if (businessLocations.isNotEmpty && selectedLocationId == null) {
          selectedLocationId = businessLocations.first['id'];
        }
        _logger.info('Business locations fetched successfully: ${businessLocations.length} locations');
        if (_state.mounted) _state.setState(() {});
      } else {
        _logger.warning('Failed to fetch business locations: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error in fetchBusinessLocations: $e');
    }
  }

  Future<void> _loadCachedData(SharedPreferences prefs) async {
    final cachedDashboard = prefs.getString('cached_dashboard_data');
    final cachedTotals = prefs.getString('cached_totals_data');
    if (cachedDashboard != null) {
      dashboardData = jsonDecode(cachedDashboard) as Map<String, dynamic>;
    }
    if (cachedTotals != null) {
      final totals = jsonDecode(cachedTotals) as Map<String, dynamic>;
      totalSalesAmount = double.tryParse(totals['total_sell']?.toString() ?? '0') ?? 0.0;
      netAmount = double.tryParse(totals['net']?.toString() ?? '0') ?? 0.0;
      invoiceDue = double.tryParse(totals['invoice_due']?.toString() ?? '0') ?? 0.0;
      totalSellReturn = double.tryParse(totals['total_sell_return']?.toString() ?? '0') ?? 0.0;
      totalPurchase = double.tryParse(totals['total_purchase']?.toString() ?? '0') ?? 0.0;
      purchaseDue = double.tryParse(totals['purchase_due']?.toString() ?? '0') ?? 0.0;
      totalPurchaseReturn = double.tryParse(totals['total_purchase_return']?.toString() ?? '0') ?? 0.0;
      totalExpense = double.tryParse(totals['total_expense']?.toString() ?? '0') ?? 0.0;
    }
  }

  Future<void> _cacheData(SharedPreferences prefs) async {
    await prefs.setString('cached_dashboard_data', jsonEncode(dashboardData));
    await prefs.setString('cached_totals_data', jsonEncode({
      'total_sell': totalSalesAmount,
      'net': netAmount,
      'invoice_due': invoiceDue,
      'total_sell_return': totalSellReturn,
      'total_purchase': totalPurchase,
      'purchase_due': purchaseDue,
      'total_purchase_return': totalPurchaseReturn,
      'total_expense': totalExpense,
    }));
  }

  Widget checkIO(BuildContext context) {
    if (checkedIn != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: !checkedIn! ? themeData.colorScheme.primary : themeData.colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: () => showCheckIODialog(context), // تغيير الاستدعاء إلى الاسم العام
                child: Text(
                  !checkedIn! ? getTranslatedText(context, 'check_in') : getTranslatedText(context, 'check_out'),
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (checkedIn!)
              Text(
                DateTime.now().difference(clockInTime).toString().split('.').first,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: themeData.colorScheme.onSurface),
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> checkIOButtonDisplay() async {
    try {
      await Attendance().getCheckInTime(Config.userId).then((value) {
        if (value != null) clockInTime = DateTime.parse(value);
      });
      final activeSubscriptionDetails = await System().get('active-subscription');
      if (activeSubscriptionDetails.isNotEmpty && activeSubscriptionDetails[0].containsKey('package_details')) {
        final packageDetails = activeSubscriptionDetails[0]['package_details'];
        if (packageDetails.containsKey('essentials_module') && packageDetails['essentials_module'].toString() == '1') {
          checkedIn = await Attendance().getAttendanceStatus(Config.userId);
          if (_state.mounted) _state.setState(() {});
        } else {
          checkedIn = null;
          if (_state.mounted) _state.setState(() {});
        }
      } else {
        checkedIn = null;
        if (_state.mounted) _state.setState(() {});
      }
    } catch (e) {
      _logger.severe('Error in checkIOButtonDisplay: $e');
    }
  }

  Widget homePageDrawer(BuildContext drawerContext) {
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.horizontal(right: Radius.circular(20))),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF583C8F), themeData.colorScheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'AshalPro ERP',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  getTranslatedText(drawerContext, 'manage_your_business'),
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              getTranslatedText(drawerContext, 'version'),
              style: TextStyle(fontFamily: 'Cairo', fontSize: 12, color: themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ListTile(
        leading: Icon(icon, color: themeData.colorScheme.primary, size: 24),
        title: Text(
          getTranslatedText(context, title),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w500, color: themeData.colorScheme.onSurface),
        ),
        onTap: () {
          onTap();
          scaffoldKey.currentState?.closeDrawer();
        },
        hoverColor: themeData.colorScheme.primary.withAlpha((0.1 * 256).toInt()),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget changeAppLanguage(BuildContext dialogContext) {
    final appLanguage = Provider.of<AppLanguage>(dialogContext, listen: false);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: themeData.colorScheme.primary.withAlpha((0.3 * 256).toInt())),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: themeData.colorScheme.surface,
          onChanged: (String? newValue) {
            appLanguage.changeLanguage(Locale(newValue!), newValue);
            selectedLanguage = newValue;
            Navigator.pop(dialogContext);
            if (_state.mounted) _state.setState(() {});
          },
          value: selectedLanguage,
          items: Config().lang.map<DropdownMenuItem<String>>((Map locale) {
            return DropdownMenuItem<String>(
              value: locale['languageCode'],
              child: Text(locale['name'], style: TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.w500)),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> sync(BuildContext context) async {
    if (syncPressed) return;
    syncPressed = true;
    showDialogMethod(context);
    try {
      if (await Helper().checkConnectivity()) {
        await Sell().createApiSell(syncAll: true);
        await Variations().refresh();
        await SystemApi().store();
        await homepageData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getTranslatedText(context, 'sync_success'))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(getTranslatedText(context, 'check_connectivity'))),
        );
      }
    } catch (e) {
      _logger.severe('Sync error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync error: $e')),
      );
    } finally {
      Navigator.pop(context);
      syncPressed = false;
    }
  }

  void showDialogMethod(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(
              getTranslatedText(dialogContext, 'sync_in_progress'),
              style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentDetails(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations?.translate('payment_details') ?? 'Payment Details',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        method.isNotEmpty
            ? Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: method.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;
              return ListTile(
                leading: Icon(
                  _getPaymentIcon(payment['key']),
                  color: themeData.colorScheme.primary,
                  size: 20,
                ),
                title: Text(
                  payment['key']?.toString() ?? 'Unknown',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                trailing: Text(
                  '$businessSymbol ${Helper().formatCurrency(payment['value'])}',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeData.colorScheme.primary,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                tileColor: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
              );
            }).toList(),
          ),
        )
            : Text(
          localizations?.translate('no_payment_data') ?? 'No payment data available',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            color: themeData.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String? key) {
    switch (key?.toLowerCase()) {
      case 'cash':
        return FontAwesomeIcons.moneyBill;
      case 'card':
        return FontAwesomeIcons.creditCard;
      case 'cheque':
        return FontAwesomeIcons.fileInvoice;
      case 'bank_transfer':
        return FontAwesomeIcons.bank;
      case 'other':
        return FontAwesomeIcons.coins;
      default:
        return FontAwesomeIcons.questionCircle;
    }
  }

  Future<void> getPermission() async {
    try {
      final status = [
        await Permission.location.status,
        await Permission.storage.status,
        await Permission.camera.status,
      ];
      notPermitted = status.contains(PermissionStatus.denied);
      if (await Helper().getPermission('essentials.allow_users_for_attendance_from_api')) {
        await checkIOButtonDisplay();
        if (_state.mounted) _state.setState(() => attendancePermission = true);
      } else {
        if (_state.mounted) _state.setState(() => checkedIn = null);
      }
      if (await Helper().getPermission('all_expense.access') || await Helper().getPermission('view_own_expense')) {
        if (_state.mounted) _state.setState(() => accessExpenses = true);
      }
    } catch (e) {
      _logger.severe('Error in getPermission: $e');
    }
  }

  Future<void> goToExpenses(BuildContext context) async {
    if (await Helper().checkConnectivity()) {
      Navigator.pushNamed(context, '/expense');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getTranslatedText(context, 'check_connectivity'))),
      );
    }
  }

  void showLanguageDialog(BuildContext context) {  // تم تغيير الاسم إلى عام
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          getTranslatedText(dialogContext, 'language'),
          style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: changeAppLanguage(dialogContext),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(getTranslatedText(dialogContext, 'cancel'), style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> navigateWithConnectivity(String route, BuildContext context) async {  // تم تغيير الاسم إلى عام
    if (await Helper().checkConnectivity()) {
      Navigator.pushNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getTranslatedText(context, 'check_connectivity'))),
      );
    }
  }

  void showCheckIODialog(BuildContext context) {  // تم تغيير الاسم إلى عام، وكان أصلاً _showCheckIODialog
    Helper().syncCallLogs();
    showDialog(
      barrierDismissible: true,
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            !checkedIn! ? getTranslatedText(dialogContext, 'check_in_note') : getTranslatedText(dialogContext, 'check_out_note'),
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600, color: themeData.colorScheme.onSurface),
          ),
          content: TextFormField(
            controller: note,
            autofocus: true,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: themeData.colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: getTranslatedText(dialogContext, 'note'),
              hintStyle: TextStyle(fontFamily: 'Cairo', color: themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt())),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: themeData.colorScheme.primary),
              onPressed: () async {
                Navigator.pop(dialogContext);
                if (await Helper().checkConnectivity()) {
                  try {
                    await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
                    ).then((Position position) {
                      currentLoc = LatLng(position.latitude, position.longitude);
                    });
                  } catch (e) {
                    _logger.warning('Error getting location: $e');
                  }
                  if (!checkedIn!) {
                    final ipAddress = IpAddress(type: RequestType.json);
                    final data = await ipAddress.getIpAddress();
                    final iP = data.toString();
                    try {
                      final checkInMap = await Attendance().doCheckIn(
                        checkInNote: note.text,
                        iPAddress: iP,
                        latitude: currentLoc?.latitude.toString() ?? '',
                        longitude: currentLoc?.longitude.toString() ?? '',
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(checkInMap.toString())));
                      note.clear();
                    } catch (e) {
                      _logger.severe('Error in check-in: $e');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Check-in error: $e')));
                    }
                  } else {
                    try {
                      final checkOutMap = await Attendance().doCheckOut(
                        latitude: currentLoc?.latitude.toString() ?? '',
                        longitude: currentLoc?.longitude.toString() ?? '',
                        checkOutNote: note.text,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(checkOutMap.toString())));
                      note.clear();
                    } catch (e) {
                      _logger.severe('Error in check-out: $e');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Check-out error: $e')));
                    }
                  }
                  checkedIn = await Attendance().getAttendanceStatus(Config.userId);
                  await Attendance().getCheckInTime(Config.userId).then((value) {
                    if (value != null) clockInTime = DateTime.parse(value);
                  });
                  if (_state.mounted) _state.setState(() {});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(getTranslatedText(context, 'check_connectivity'))),
                  );
                }
              },
              child: Text(getTranslatedText(context, 'ok'), style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(getTranslatedText(dialogContext, 'cancel'), style: TextStyle(fontFamily: 'Cairo', fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notSyncedSells = await SellDatabase().getNotSyncedSells();
      if (notSyncedSells.isEmpty) {
        await prefs.setInt('prevUserId', Config.userId!);
        await prefs.remove('userId');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(
                getTranslatedText(dialogContext, 'pending_sync'),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600),
              ),
              content: Text(
                getTranslatedText(dialogContext, 'sync_all_sales_before_logout'),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await sync(context);
                    await handleLogout(context);
                  },
                  child: Text(
                    getTranslatedText(dialogContext, 'sync'),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: themeData.colorScheme.primary),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await prefs.setInt('prevUserId', Config.userId!);
                    await prefs.remove('userId');
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    getTranslatedText(dialogContext, 'logout_without_sync'),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.redAccent),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    getTranslatedText(dialogContext, 'cancel'),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      _logger.severe('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _logger.warning('No token available for fetchDashboardData');
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        dashboardData = jsonDecode(response.body)['data'] ?? {};
        _logger.info('Dashboard data fetched successfully');
        if (_state.mounted) _state.setState(() {});
      } else {
        _logger.warning('Failed to fetch dashboard data: ${response.statusCode}');
        ScaffoldMessenger.of(_state.context).showSnackBar(
          SnackBar(content: Text(getTranslatedText(_state.context, 'failed_to_load_dashboard'))),
        );
      }
    } catch (e) {
      _logger.severe('Error in fetchDashboardData: $e');
      ScaffoldMessenger.of(_state.context).showSnackBar(
        SnackBar(content: Text(getTranslatedText(_state.context, 'failed_to_load_dashboard'))),
      );
    }
  }

  Future<void> fetchTotals(String start, String end, {int? locationId}) async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _logger.warning('No token available for fetchTotals');
        return;
      }
      var uri = '${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/dashboard/totals?start=$start&end=$end';
      if (locationId != null) {
        uri += '&location_id=$locationId';
      }
      final response = await http.get(
        Uri.parse(uri),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] ?? {};
        totalSalesAmount = double.tryParse(data['total_sell']?.toString() ?? '0') ?? 0.0;
        netAmount = double.tryParse(data['net']?.toString() ?? '0') ?? 0.0;
        invoiceDue = double.tryParse(data['invoice_due']?.toString() ?? '0') ?? 0.0;
        totalSellReturn = double.tryParse(data['total_sell_return']?.toString() ?? '0') ?? 0.0;
        totalPurchase = double.tryParse(data['total_purchase']?.toString() ?? '0') ?? 0.0;
        purchaseDue = double.tryParse(data['purchase_due']?.toString() ?? '0') ?? 0.0;
        totalPurchaseReturn = double.tryParse(data['total_purchase_return']?.toString() ?? '0') ?? 0.0;
        totalExpense = double.tryParse(data['total_expense']?.toString() ?? '0') ?? 0.0;
        _logger.info('Totals fetched successfully');
        if (_state.mounted) _state.setState(() {});
      } else {
        _logger.warning('Failed to fetch totals: ${response.statusCode}');
        ScaffoldMessenger.of(_state.context).showSnackBar(
          SnackBar(content: Text(getTranslatedText(_state.context, 'failed_to_load_dashboard'))),
        );
      }
    } catch (e) {
      _logger.severe('Error in fetchTotals: $e');
      ScaffoldMessenger.of(_state.context).showSnackBar(
        SnackBar(content: Text(getTranslatedText(_state.context, 'failed_to_load_dashboard'))),
      );
    }
  }

  Future<void> fetchStockAlerts() async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _logger.warning('No token available for fetchStockAlerts');
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/dashboard/product-stock-alert'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        stockAlerts = List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] ?? []);
        _logger.info('Stock alerts fetched successfully: ${stockAlerts.length} items');
        if (_state.mounted) _state.setState(() {});
      } else {
        _logger.warning('Failed to fetch stock alerts: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error in fetchStockAlerts: $e');
    }
  }

  Future<void> fetchPurchaseDues() async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _logger.warning('No token available for fetchPurchaseDues');
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/dashboard/purchase-payment-dues'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        purchaseDues = List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] ?? []);
        _logger.info('Purchase dues fetched successfully: ${purchaseDues.length} items');
        if (_state.mounted) _state.setState(() {});
      } else {
        _logger.warning('Failed to fetch purchase dues: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error in fetchPurchaseDues: $e');
    }
  }

  Future<void> fetchSalesDues() async {
    try {
      final token = await System().getToken();
      if (token == null) {
        _logger.warning('No token available for fetchSalesDues');
        return;
      }
      final response = await http.get(
        Uri.parse('${ApiEndPoints.baseUrl}${ApiEndPoints.apiUrl}/dashboard/sales-payment-dues'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        salesDues = List<Map<String, dynamic>>.from(jsonDecode(response.body)['data'] ?? []);
        _logger.info('Sales dues fetched successfully: ${salesDues.length} items');
        if (_state.mounted) _state.setState(() {});
      } else {
        _logger.warning('Failed to fetch sales dues: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('Error in fetchSalesDues: $e');
    }
  }

  Future<List> loadStatistics() async {
    try {
      final result = await SellDatabase().getSells();
      totalSales = result.length;
      if (_state.mounted) {
        _state.setState(() {
          for (final sell in result) {
            PaymentDatabase().get(sell['id'], allColumns: true).then((payment) {
              double paidAmount = 0.0, returnAmount = 0.0;
              for (final element in payment) {
                if (element['is_return'] == 0) {
                  paidAmount += double.tryParse(element['amount']?.toString() ?? '0') ?? 0.0;
                  payments.add({'key': element['method'] ?? 'Unknown', 'value': element['amount'] ?? 0.0});
                } else {
                  returnAmount = double.tryParse(element['amount']?.toString() ?? '0') ?? 0.0;
                }
              }
              totalSalesAmount += double.tryParse(sell['invoice_amount']?.toString() ?? '0') ?? 0.0;
              netAmount += (paidAmount - returnAmount);
              invoiceDue += double.tryParse(sell['pending_amount']?.toString() ?? '0') ?? 0.0;
              if (_state.mounted) _state.setState(() {});
            });
          }
        });
      }
      return result;
    } catch (e) {
      _logger.severe('Error in loadStatistics: $e');
      return [];
    }
  }

  Future<void> loadPaymentDetails() async {
    try {
      final paymentMethod = [];
      await System().get('payment_methods').then((value) => value.forEach((element) => element.forEach((k, v) => paymentMethod.add({'key': k.toString(), 'value': v.toString()}))));
      await loadStatistics().then((value) {
        Future.delayed(const Duration(seconds: 1), () {
          method.clear();
          for (final row in payments) {
            final value = double.tryParse(row['value']?.toString() ?? '0') ?? 0.0;
            if (row['key'] == 'cash') byCash += value;
            if (row['key'] == 'card') byCard += value;
            if (row['key'] == 'cheque') byCheque += value;
            if (row['key'] == 'bank_transfer') byBankTransfer += value;
            if (row['key'] == 'other') byOther += value;
            if (row['key'] == 'custom_pay_1') byCustomPayment_1 += value;
            if (row['key'] == 'custom_pay_2') byCustomPayment_2 += value;
            if (row['key'] == 'custom_pay_3') byCustomPayment_3 += value;
          }
          for (final row in paymentMethod) {
            if (byCash > 0 && row['key'] == 'cash') method.add({'key': row['value'], 'value': byCash});
            if (byCard > 0 && row['key'] == 'card') method.add({'key': row['value'], 'value': byCard});
            if (byCheque > 0 && row['key'] == 'cheque') method.add({'key': row['value'], 'value': byCheque});
            if (byBankTransfer > 0 && row['key'] == 'bank_transfer') method.add({'key': row['value'], 'value': byBankTransfer});
            if (byOther > 0 && row['key'] == 'other') method.add({'key': row['value'], 'value': byOther});
            if (byCustomPayment_1 > 0 && row['key'] == 'custom_pay_1') method.add({'key': row['value'], 'value': byCustomPayment_1});
            if (byCustomPayment_2 > 0 && row['key'] == 'custom_pay_2') method.add({'key': row['value'], 'value': byCustomPayment_2});
            if (byCustomPayment_3 > 0 && row['key'] == 'custom_pay_3') method.add({'key': row['value'], 'value': byCustomPayment_3});
          }
          if (_state.mounted) _state.setState(() {});
        });
      });
    } catch (e) {
      _logger.severe('Error in loadPaymentDetails: $e');
    }
  }

  Map<String, String> _calculateDateRange(String period) {
    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');
    String start = '';
    String end = format.format(now);

    switch (period) {
      case 'today':
        start = end;
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        start = format.format(yesterday);
        end = start;
        break;
      case 'last_7_days':
        final last7 = now.subtract(const Duration(days: 6));
        start = format.format(last7);
        break;
      case 'this_month':
        final firstDayOfMonth = DateTime(now.year, now.month, 1);
        start = format.format(firstDayOfMonth);
        break;
      case 'last_year':
        final lastYear = now.subtract(const Duration(days: 365));
        start = format.format(lastYear);
        break;
      case 'previous_year':
        final previousYearStart = DateTime(now.year - 1, 1, 1);
        final previousYearEnd = DateTime(now.year - 1, 12, 31);
        start = format.format(previousYearStart);
        end = format.format(previousYearEnd);
        break;
      default:
        start = end;
    }

    return {'start': start, 'end': end};
  }

  Future<void> refreshData(BuildContext context, {String? period, String? startDate, String? endDate, int? locationId}) async {
    if (period != null) {
      selectedPeriod = period;
      if (_state.mounted) _state.setState(() {});
    }

    final dateRange = period != null ? _calculateDateRange(period) : {'start': startDate ?? '', 'end': endDate ?? ''};
    final start = dateRange['start']!;
    final end = dateRange['end']!;

    try {
      await fetchDashboardData();
      await fetchTotals(start, end, locationId: locationId ?? selectedLocationId);
      await fetchStockAlerts();
      await fetchPurchaseDues();
      await fetchSalesDues();
      final prefs = await SharedPreferences.getInstance();
      await _cacheData(prefs);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getTranslatedText(context, 'data_refreshed'))),
      );
    } catch (e) {
      _logger.severe('Error in refreshData: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh error: $e')),
      );
    }
  }

  void updateSelectedLocation(int? newLocationId) {
    selectedLocationId = newLocationId;
    if (_state.mounted) _state.setState(() {});
    refreshData(_state.context);
  }
}