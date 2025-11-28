import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/pages/product_stock_report.dart';
import 'package:pos_final/pages/profit_loss_report.dart';
import '../locale/my_localizations.dart';

class ReportScreen extends StatelessWidget {
  ReportScreen({super.key});
  static const String routeName = '/ReportScreen';

  static int themeType = 1;
  final ThemeData themeData = AppTheme.getThemeFromThemeMode(themeType);
  final CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(themeType);

  @override
  Widget build(BuildContext context) {
    // Helper function to safely translate with fallback
    String safeTranslate(String key, {String fallback = ''}) {
      try {
        return AppLocalizations.of(context).translate(key);
      } catch (e) {
        return fallback;
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: Text(
          safeTranslate('reports', fallback: 'Reports'),
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
              FontAwesomeIcons.filter,
              color: themeData.colorScheme.primary,
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    safeTranslate('coming_soon', fallback: 'Coming soon!'),
                    style: TextStyle(
            fontFamily: 'Cairo',fontSize: 14),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: MySize.size16!),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(MySize.size24!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              safeTranslate('overview_reports', fallback: 'Overview Reports'),
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: themeData.colorScheme.primary,
              ),
            ),
            SizedBox(height: MySize.size8!),
            Text(
              safeTranslate('select_report_to_view',
                  fallback: 'Select a report to view details'),
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: MySize.size24!),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: MySize.size24!,
                mainAxisSpacing: MySize.size24!,
                childAspectRatio: 1.5,
                children: [
                  _ReportCard(
                    title: safeTranslate('profit_and_loss',
                        fallback: 'Profit and Loss'),
                    subtitle: safeTranslate('view_financial_performance',
                        fallback: 'View financial performance'),
                    icon: FontAwesomeIcons.chartLine,
                    color: themeData.colorScheme.primary,
                    onTap: () {
                      Navigator.pushNamed(
                          context, ProfitLossReportScreen.routeName);
                    },
                  ),
                  _ReportCard(
                    title: safeTranslate('products_stock',
                        fallback: 'Products Stock'),
                    subtitle: safeTranslate('track_inventory_levels',
                        fallback: 'Track inventory levels'),
                    icon: FontAwesomeIcons.boxesStacked,
                    color: themeData.colorScheme.secondary,
                    onTap: () {
                      Navigator.pushNamed(
                          context, ProductStockReportScreen.routeName);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  __ReportCardState createState() => __ReportCardState();
}

class __ReportCardState extends State<_ReportCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(_isHovered ? 1.03 : 1.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((_isHovered ? 0.2 : 0.1 * 256).toInt()),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 6 : 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(MySize.size16!),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(MySize.size12!),
                decoration: BoxDecoration(
                  color: widget.color.withAlpha((0.1*256).toInt()),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: widget.color,
                ),
              ),
              SizedBox(height: MySize.size16!),
              Text(
                widget.title,
                style: TextStyle(
            fontFamily: 'Cairo',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: MySize.size8!),
              Text(
                widget.subtitle,
                style: TextStyle(
            fontFamily: 'Cairo',
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}