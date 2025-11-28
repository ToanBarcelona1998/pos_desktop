import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:intl/intl.dart';
import 'package:pos_final/pages/home/home_logic.dart';

class Statistics extends StatelessWidget {
  const Statistics({
    super.key,
    required this.themeData,
    required this.businessSymbol,
    required this.totalSales,
    required this.totalSalesAmount,
    required this.netAmount,
    required this.invoiceDue,
    required this.totalSellReturn,
    required this.totalPurchase,
    required this.purchaseDue,
    required this.totalPurchaseReturn,
    required this.totalExpense,
    required this.stockAlerts,
    required this.purchaseDues,
    required this.salesDues,
    required this.dashboardData,
    required this.businessLocations,
    required this.selectedLocationId,
    required this.homeLogic,
  });

  final ThemeData themeData;
  final String businessSymbol;
  final int? totalSales;
  final double totalSalesAmount;
  final double netAmount;
  final double invoiceDue;
  final double totalSellReturn;
  final double totalPurchase;
  final double purchaseDue;
  final double totalPurchaseReturn;
  final double totalExpense;
  final List<Map<String, dynamic>> stockAlerts;
  final List<Map<String, dynamic>> purchaseDues;
  final List<Map<String, dynamic>> salesDues;
  final Map<String, dynamic> dashboardData;
  final List<Map<String, dynamic>> businessLocations;
  final int? selectedLocationId;
  final HomeLogic homeLogic;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      return const Center(child: Text('Localization not initialized'));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان الإحصائيات مع تدرج لوني محسن
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeData.colorScheme.primary, themeData.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: themeData.colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(FontAwesomeIcons.chartPie, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                localizations.translate('statistics') ?? 'Statistics',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // فلترة حسب الفرع والفترة الزمنية مع تحسينات
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shadowColor: Colors.black.withOpacity(0.15),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.filter, color: themeData.colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      localizations.translate('filters') ?? 'Filters',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: themeData.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // فلتر الفرع
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        decoration: InputDecoration(
                          labelText: localizations.translate('location') ?? 'Location',
                          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: themeData.colorScheme.primary.withOpacity(0.5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: themeData.colorScheme.primary.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2),
                          ),
                          prefixIcon: Icon(FontAwesomeIcons.mapMarkerAlt, color: themeData.colorScheme.primary),
                        ),
                        value: selectedLocationId,
                        items: [
                          DropdownMenuItem<int>(
                            value: null,
                            child: Text(localizations.translate('all_locations') ?? 'All Locations', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          ),
                          ...businessLocations.map((location) => DropdownMenuItem<int>(
                            value: location['id'],
                            child: Text(location['name'], style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          )),
                        ],
                        onChanged: (value) {
                          homeLogic.updateSelectedLocation(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    // فلتر الفترة الزمنية (Dropdown للخيارات السريعة)
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: localizations.translate('period') ?? 'Period',
                          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: themeData.colorScheme.primary.withOpacity(0.5)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: themeData.colorScheme.primary.withOpacity(0.5)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: themeData.colorScheme.primary, width: 2),
                          ),
                          prefixIcon: Icon(FontAwesomeIcons.calendarAlt, color: themeData.colorScheme.primary),
                        ),
                        value: homeLogic.selectedPeriod,
                        items: [
                          DropdownMenuItem<String>(
                            value: 'today',
                            child: Text(localizations.translate('today') ?? 'Today', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          ),
                          DropdownMenuItem<String>(
                            value: 'yesterday',
                            child: Text(localizations.translate('yesterday') ?? 'Yesterday', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          ),
                          DropdownMenuItem<String>(
                            value: 'last_7_days',
                            child: Text(localizations.translate('last_7_days') ?? 'Last 7 Days', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          ),
                          DropdownMenuItem<String>(
                            value: 'this_month',
                            child: Text(localizations.translate('this_month') ?? 'This Month', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          ),
                          DropdownMenuItem<String>(
                            value: 'last_year',
                            child: Text(localizations.translate('last_year') ?? 'Last Year', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          ),
                          DropdownMenuItem<String>(
                            value: 'previous_year',
                            child: Text(localizations.translate('previous_year') ?? 'Previous Year', style: const TextStyle(fontFamily: 'Cairo', fontSize: 16)),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            homeLogic.refreshData(context, period: value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    // زر لاختيار نطاق تاريخ مخصص
                    ElevatedButton.icon(
                      icon: const Icon(FontAwesomeIcons.calendarDays, size: 20),
                      label: Text(
                        localizations.translate('custom_range') ?? 'Custom Range',
                        style: const TextStyle(fontFamily: 'Cairo', fontSize: 16),
                      ),
                      onPressed: () async {
                        final DateTimeRange? picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: themeData.colorScheme.primary,
                                  onPrimary: Colors.white,
                                  surface: themeData.colorScheme.surface,
                                  onSurface: themeData.colorScheme.onSurface,
                                ),
                                dialogBackgroundColor: Colors.white,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          final startDate = DateFormat('yyyy-MM-dd').format(picked.start);
                          final endDate = DateFormat('yyyy-MM-dd').format(picked.end);
                          homeLogic.refreshData(
                            context,
                            startDate: startDate,
                            endDate: endDate,
                            locationId: selectedLocationId,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // النظرة العامة (Overview) مع عرض 4 بطاقات في السطر
        Card(
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          shadowColor: Colors.black.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.chartBar, color: themeData.colorScheme.primary, size: 30),
                    const SizedBox(width: 12),
                    Text(
                      localizations.translate('overview') ?? 'Overview',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeData.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.6,
                  children: [
                    _buildStatCard(context, 'total_sales', FontAwesomeIcons.chartLine, '$businessSymbol ${totalSalesAmount.toStringAsFixed(2)}', Colors.greenAccent),
                    _buildStatCard(context, 'net', FontAwesomeIcons.moneyBillWave, '$businessSymbol ${netAmount.toStringAsFixed(2)}', Colors.blueAccent),
                    _buildStatCard(context, 'invoice_due', FontAwesomeIcons.exclamationTriangle, '$businessSymbol ${invoiceDue.toStringAsFixed(2)}', Colors.redAccent),
                    _buildStatCard(context, 'total_sell_return', FontAwesomeIcons.undo, '$businessSymbol ${totalSellReturn.toStringAsFixed(2)}', Colors.purpleAccent),
                    _buildStatCard(context, 'total_purchase', FontAwesomeIcons.shoppingCart, '$businessSymbol ${totalPurchase.toStringAsFixed(2)}', Colors.orangeAccent),
                    _buildStatCard(context, 'purchase_due', FontAwesomeIcons.exclamationCircle, '$businessSymbol ${purchaseDue.toStringAsFixed(2)}', Colors.redAccent),
                    _buildStatCard(context, 'total_purchase_return', FontAwesomeIcons.undoAlt, '$businessSymbol ${totalPurchaseReturn.toStringAsFixed(2)}', Colors.purpleAccent),
                    _buildStatCard(context, 'expense', FontAwesomeIcons.moneyCheckAlt, '$businessSymbol ${totalExpense.toStringAsFixed(2)}', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // مخطط المبيعات مع تحسينات
        Card(
          elevation: 10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          shadowColor: Colors.black.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(FontAwesomeIcons.chartLine, color: themeData.colorScheme.primary, size: 30),
                    const SizedBox(width: 12),
                    Text(
                      localizations.translate('sales_chart') ?? 'Sales Chart',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: themeData.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: isDesktop ? 350 : 250,
                  child: dashboardData.containsKey('sells_chart_1') && dashboardData['sells_chart_1'] != null
                      ? _buildLineChart(context)
                      : Center(
                    child: Text(
                      localizations.translate('no_sales_data') ?? 'No sales data',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 20,
                        color: themeData.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // تنبيهات المخزون
        _buildExpandableSection(
          context,
          localizations.translate('stock_alerts') ?? 'Stock Alerts',
          FontAwesomeIcons.boxOpen,
          Colors.redAccent,
          stockAlerts.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stockAlerts.length,
            itemBuilder: (context, index) {
              return _buildListItem(
                icon: FontAwesomeIcons.exclamationCircle,
                iconColor: Colors.redAccent,
                title: stockAlerts[index]['product']?.toString() ?? 'Unknown',
                subtitle: stockAlerts[index]['stock']?.toString() ?? 'N/A',
                subtitleColor: Colors.redAccent,
              );
            },
          )
              : Center(
            child: Text(
              localizations.translate('no_stock_alerts') ?? 'No stock alerts',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                color: themeData.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // ديون المشتريات
        _buildExpandableSection(
          context,
          localizations.translate('purchase_dues') ?? 'Purchase Dues',
          FontAwesomeIcons.fileInvoiceDollar,
          themeData.colorScheme.primary,
          purchaseDues.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: purchaseDues.length,
            itemBuilder: (context, index) {
              return _buildListItem(
                icon: FontAwesomeIcons.user,
                iconColor: themeData.colorScheme.primary,
                title: purchaseDues[index]['supplier']?.toString() ?? 'Unknown',
                subtitle: '${localizations.translate('ref_no') ?? 'Ref No'}: ${purchaseDues[index]['ref_no']?.toString() ?? 'N/A'} - ${localizations.translate('due') ?? 'Due'}: $businessSymbol ${purchaseDues[index]['due']?.toString() ?? '0.0'}',
              );
            },
          )
              : Center(
            child: Text(
              localizations.translate('no_purchase_dues') ?? 'No purchase dues',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                color: themeData.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // ديون المبيعات
        _buildExpandableSection(
          context,
          localizations.translate('sales_dues') ?? 'Sales Dues',
          FontAwesomeIcons.fileInvoice,
          themeData.colorScheme.primary,
          salesDues.isNotEmpty
              ? ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: salesDues.length,
            itemBuilder: (context, index) {
              return _buildListItem(
                icon: FontAwesomeIcons.user,
                iconColor: themeData.colorScheme.primary,
                title: salesDues[index]['customer']?.toString() ?? 'Unknown',
                subtitle: '${localizations.translate('invoice_no') ?? 'Invoice No'}: ${salesDues[index]['invoice_no']?.toString() ?? 'N/A'} - ${localizations.translate('due') ?? 'Due'}: $businessSymbol ${salesDues[index]['due']?.toString() ?? '0.0'}',
              );
            },
          )
              : Center(
            child: Text(
              localizations.translate('no_sales_dues') ?? 'No sales dues',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                color: themeData.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, IconData icon, String value, Color accentColor) {
    final localizations = AppLocalizations.of(context);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: accentColor.withOpacity(0.3),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor.withOpacity(0.1), accentColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: accentColor, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.translate(label) ?? label,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 20,
                      color: themeData.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final chartData = dashboardData['sells_chart_1'] as Map<String, dynamic>?;

    final labels = (chartData != null && chartData.containsKey('labels') && chartData['labels'] is List)
        ? (chartData['labels'] as List).cast<String>()
        : [];

    final data = (chartData != null && chartData.containsKey('datasets') && chartData['datasets'] is List && (chartData['datasets'] as List).isNotEmpty)
        ? ((chartData['datasets'] as List)[0]['data'] as List<dynamic>?)?.cast<num>() ?? []
        : [];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          verticalInterval: 1,
          getDrawingVerticalLine: (value) => FlLine(
            color: themeData.colorScheme.onSurface.withOpacity(0.15),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
          drawHorizontalLine: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(
            color: themeData.colorScheme.onSurface.withOpacity(0.15),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 1,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: themeData.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Text(
                    labels[index],
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 14,
                      color: themeData.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: themeData.colorScheme.onSurface.withOpacity(0.15)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
            isCurved: true,
            color: themeData.colorScheme.primary,
            barWidth: 5,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  themeData.colorScheme.primary.withOpacity(0.3),
                  themeData.colorScheme.primary.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 5,
                color: Colors.white,
                strokeWidth: 3,
                strokeColor: themeData.colorScheme.primary,
              ),
            ),
            lineChartStepData: LineChartStepData(),
          ),
        ],
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => themeData.colorScheme.primary.withOpacity(0.9),
            tooltipPadding: const EdgeInsets.all(10),
            tooltipBorder: BorderSide(color: themeData.colorScheme.primary, width: 1),
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(2)} $businessSymbol',
                const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          handleBuiltInTouches: true,
        ),
      ),
    );
  }

  Widget _buildExpandableSection(BuildContext context, String title, IconData icon, Color iconColor, Widget content) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      shadowColor: Colors.black.withOpacity(0.2),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 30),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onSurface,
          ),
        ),
        iconColor: themeData.colorScheme.primary,
        collapsedIconColor: themeData.colorScheme.onSurface.withOpacity(0.7),
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? subtitleColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.1),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            color: subtitleColor ?? Colors.black87,
          ),
        ),
      ),
    );
  }
}