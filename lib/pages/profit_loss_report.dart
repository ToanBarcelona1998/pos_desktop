import 'dart:developer' as dev;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import '../apis/profit_loss_report.dart';
import '../helpers/app_theme.dart';
import '../locale/my_localizations.dart';
import '../models/profit_loss_report_model.dart';

class ProfitLossReportScreen extends StatefulWidget {
  static const String routeName = '/ProfitLossReport';
  const ProfitLossReportScreen({super.key});

  static int themeType = 1;

  @override
  State<ProfitLossReportScreen> createState() => _ProfitLossReportScreenState();
}

class _ProfitLossReportScreenState extends State<ProfitLossReportScreen> {
  // Theme and styling
  ThemeData themeData = AppTheme.getThemeFromThemeMode(ProfitLossReportScreen.themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(ProfitLossReportScreen.themeType);

  // State variables
  ProfitLossReportModel? profitLossReportModel;
  bool loading = true;
  Map<String, dynamic>? mapData;
  List<Map<String, dynamic>> myReports = [];
  List<Map<String, dynamic>> filteredReports = [];
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  int _rowsPerPage = 8;

  // Alternating row colors
  final List<Color> rowColors = [Colors.white, Colors.grey[50]!];

  // Responsive text style
  TextStyle getTextStyle(BuildContext context, {bool isHeader = false}) {
    return AppTheme.getTextStyle(
      themeData.textTheme.bodyMedium,
      fontSize: isHeader ? 20 : 16,
      fontWeight: isHeader ? 700 : 500,
      color: themeData.colorScheme.onSurface,
    );
  }

  Future<void> _getProfitLossReport() async {
    dev.log("Fetching profit loss report");
    setState(() {
      loading = true;
    });

    try {
      var result = await ProfitLossReportService().getProfitLossReport();
      setState(() {
        if (result == null) {
          loading = false;
        } else {
          profitLossReportModel = result;
          mapData = profitLossReportModel!.toJson();
          myReports = mapData!.entries
              .map((e) => {"title": e.key, "data": e.value.toString()})
              .toList();
          filteredReports = myReports;
          dev.log("myReports ${myReports.isNotEmpty ? myReports[0] : 'empty'}");
          loading = false;
        }
      });
    } catch (e) {
      dev.log("Error fetching profit loss report: $e");
      setState(() {
        loading = false;
      });
    }
  }

  void _filterReports(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredReports = myReports;
      } else {
        filteredReports = myReports.where((report) {
          final title = _safeTranslate(context, report['title'], report['title']).toLowerCase();
          final data = report['data'].toLowerCase();
          return title.contains(query.toLowerCase()) || data.contains(query.toLowerCase());
        }).toList();
      }
      _currentPage = 0;
    });
  }

  Future<void> _exportToCsv() async {
    try {
      List<List<dynamic>> csvData = [
        ['Metric', 'Value'],
        ...filteredReports.map((report) => [
          _safeTranslate(context, report['title'], report['title']),
          report['data'],
        ]),
      ];

      String csv = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csv);
      await FileSaver.instance.saveFile(
        name: 'profit_loss_report_${DateTime.now().toIso8601String()}.csv',
        bytes: bytes,
        mimeType: MimeType.csv,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_safeTranslate(context, 'export_success', 'Export Successful')),
            backgroundColor: customAppTheme.colorSuccess,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      dev.log("Export error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_safeTranslate(context, 'export_failed', 'Export Failed')),
            backgroundColor: customAppTheme.colorError,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _getProfitLossReport();
    _searchController.addListener(() {
      _filterReports(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AppLocalizations.of(context).load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    themeData.colorScheme.primary,
                    themeData.colorScheme.primary.withAlpha((0.7 * 256).toInt()),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            title: Text(
              _safeTranslate(context, 'reports', 'Profit & Loss Report'),
              style: AppTheme.getTextStyle(
                themeData.textTheme.titleLarge,
                fontSize: 26,
                fontWeight: 700,
                color: themeData.colorScheme.onPrimary,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download),
                color: themeData.colorScheme.onPrimary,
                tooltip: _safeTranslate(context, 'export_csv', 'Export to CSV'),
                onPressed: filteredReports.isEmpty ? null : _exportToCsv,
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                color: themeData.colorScheme.onPrimary,
                tooltip: _safeTranslate(context, 'refresh', 'Refresh'),
                onPressed: _getProfitLossReport,
              ),
            ],
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeData.scaffoldBackgroundColor,
                  themeData.scaffoldBackgroundColor.withAlpha((0.9 * 256).toInt()),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : filteredReports.isEmpty && _searchController.text.isEmpty
                ? _buildEmptyState(context)
                : _buildReportContent(context),
          ),
        );
      },
    );
  }

  String _safeTranslate(BuildContext context, String key, String fallback) {
    try {
      return AppLocalizations.of(context).translate(key);
    } catch (e) {
      dev.log("Translation error for key '$key': $e");
      return fallback;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: themeData.colorScheme.onSurface.withAlpha((0.5 * 256).toInt()),
        ),
        const SizedBox(height: 16),
        Text(
          _safeTranslate(context, 'no_data_available', 'No Data Available'),
          style: getTextStyle(context).copyWith(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _getProfitLossReport,
          icon: const Icon(Icons.refresh, size: 20),
          label: Text(_safeTranslate(context, 'retry', 'Retry')),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeData.colorScheme.primary,
            foregroundColor: themeData.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: getTextStyle(context).copyWith(fontSize: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildReportContent(BuildContext context) {
    final totalPages = (filteredReports.length / _rowsPerPage).ceil();
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, filteredReports.length);
    final paginatedReports = filteredReports.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and Controls
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: themeData.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: themeData.colorScheme.onSurface.withAlpha((0.1 * 256).toInt()),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: _safeTranslate(context, 'search', 'Search reports...'),
                    prefixIcon: Icon(
                      Icons.search,
                      color: themeData.colorScheme.onSurface.withAlpha((0.6 * 256).toInt()),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: themeData.colorScheme.surface.withAlpha((0.8 * 256).toInt()),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: getTextStyle(context),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<int>(
                value: _rowsPerPage,
                items: [8, 16, 24].map((rows) {
                  return DropdownMenuItem<int>(
                    value: rows,
                    child: Text('$rows ${_safeTranslate(context, 'rows_per_page', 'rows')}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _rowsPerPage = value!;
                    _currentPage = 0;
                  });
                },
                style: getTextStyle(context),
                dropdownColor: themeData.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: themeData.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        // Report Cards
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 500,
              childAspectRatio: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: paginatedReports.length,
            itemBuilder: (context, index) {
              final report = paginatedReports[index];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: rowColors[index % 2],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: themeData.colorScheme.onSurface.withAlpha((0.05 * 256).toInt()),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _safeTranslate(context, report['title'], report['title']),
                          style: getTextStyle(context).copyWith(
                            fontWeight: FontWeight.w600,
                            color: themeData.colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatNumber(report['data']),
                          style: getTextStyle(context),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Pagination
        if (totalPages > 1) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: themeData.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: themeData.colorScheme.onSurface.withAlpha((0.1 * 256).toInt()),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_safeTranslate(context, 'showing', 'Showing')} ${startIndex + 1}-$endIndex ${_safeTranslate(context, 'of', 'of')} ${filteredReports.length}',
                  style: getTextStyle(context),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chevron_left,
                        color: _currentPage > 0
                            ? themeData.colorScheme.primary
                            : themeData.colorScheme.onSurface.withAlpha((0.3 * 256).toInt()),
                      ),
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: themeData.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_currentPage + 1} / $totalPages',
                        style: getTextStyle(context).copyWith(
                          color: themeData.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.chevron_right,
                        color: _currentPage < totalPages - 1
                            ? themeData.colorScheme.primary
                            : themeData.colorScheme.onSurface.withAlpha((0.3 * 256).toInt()),
                      ),
                      onPressed: _currentPage < totalPages - 1
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatNumber(String value) {
    try {
      final number = double.parse(value);
      return NumberFormat('#,##0.00').format(number);
    } catch (e) {
      return value;
    }
  }
}