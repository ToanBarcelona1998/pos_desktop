import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/units/units_logic.dart';

class UnitsStatisticsWidget extends StatelessWidget {
  final UnitsLogic logic;

  const UnitsStatisticsWidget({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.translate('statistics') ?? 'Statistics',
              style: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard('total_units', logic.totalUnits, Colors.blueAccent, context),
                _buildStatCard('base_units', logic.baseUnits, Colors.greenAccent, context),
                _buildStatCard('sub_units', logic.subUnits, Colors.orangeAccent, context),
                _buildStatCard('decimal_units', logic.decimalUnits, Colors.purpleAccent, context),
                _buildStatCard('whole_units', logic.wholeUnits, Colors.redAccent, context),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 280,
              child: PieChart(
                PieChartData(
                  sections: _getSections(),
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // يمكن إضافة تفاعل هنا إذا لزم
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getSections() {
    return [
      PieChartSectionData(
        value: logic.baseUnits.toDouble(),
        color: Colors.greenAccent,
        title: '${logic.baseUnits} Base',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: logic.subUnits.toDouble(),
        color: Colors.orangeAccent,
        title: '${logic.subUnits} Sub',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: logic.decimalUnits.toDouble(),
        color: Colors.purpleAccent,
        title: '${logic.decimalUnits} Decimal',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: logic.wholeUnits.toDouble(),
        color: Colors.redAccent,
        title: '${logic.wholeUnits} Whole',
        radius: 100,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  Widget _buildStatCard(String label, int value, Color color, BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          // يمكن إضافة فلتر عند النقر، e.g., filter by type
        },
        child: Card(
          elevation: 4,
          color: color.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(value.toString(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}