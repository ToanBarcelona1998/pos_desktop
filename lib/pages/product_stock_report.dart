import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/apis/product_stock_report.dart';
import 'package:pos_final/helpers/app_theme.dart';
import 'package:pos_final/helpers/size_config.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/models/product_stock_report_model.dart';

class ProductStockReportScreen extends StatefulWidget {
  static const String routeName = '/ProductStockReport';
  const ProductStockReportScreen({super.key});

  static int themeType = 1;

  @override
  State<ProductStockReportScreen> createState() => _ProductStockReportScreenState();
}

class _ProductStockReportScreenState extends State<ProductStockReportScreen> {
  ThemeData themeData = AppTheme.getThemeFromThemeMode(ProductStockReportScreen.themeType);
  CustomAppTheme customAppTheme = AppTheme.getCustomAppTheme(ProductStockReportScreen.themeType);

  List<ProductStockReportModel> myProductReportList = [];
  bool loading = true;
  bool showTableView = false; // Toggle between card and table view
  int currentPage = 0;
  final int itemsPerPage = 10;
  String searchQuery = '';
  String? sortColumn;
  bool sortAscending = true;

  Future<void> _getProductStockReport() async {
    dev.log("Fetching product stock report");
    setState(() => loading = true);

    var result = await ProductStockReportService().getProductStockReport();
    setState(() {
      if (result == null) {
        myProductReportList = [];
      } else {
        myProductReportList = result;
      }
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _getProductStockReport();
  }

  // Helper for safe translations
  String safeTranslate(String key, {String fallback = ''}) {
    try {
      return AppLocalizations.of(context).translate(key);
    } catch (e) {
      return fallback;
    }
  }

  // Filter and sort data
  List<ProductStockReportModel> getFilteredData() {
    var filtered = myProductReportList.where((item) {
      final query = searchQuery.toLowerCase();
      return item.product!.toLowerCase().contains(query) ||
          item.sku!.toLowerCase().contains(query) ||
          item.categoryName!.toLowerCase().contains(query);
    }).toList();

    if (sortColumn != null) {
      filtered.sort((a, b) {
        int compare;
        switch (sortColumn) {
          case 'total_sold':
            compare = (double.tryParse(a.totalSold ?? '0') ?? 0)
                .compareTo(double.tryParse(b.totalSold ?? '0') ?? 0);
            break;
          case 'stock':
            compare = (double.tryParse(a.stock ?? '0') ?? 0)
                .compareTo(double.tryParse(b.stock ?? '0') ?? 0);
            break;
          case 'product':
            compare = a.product!.compareTo(b.product!);
            break;
          default:
            return 0;
        }
        return sortAscending ? compare : -compare;
      });
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = getFilteredData();
    final pageCount = (filteredData.length / itemsPerPage).ceil();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 2,
        backgroundColor: Colors.white,
        title: Text(
          safeTranslate('products_stock', fallback: 'Products Stock'),
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
              showTableView ? FontAwesomeIcons.solidIdCard : FontAwesomeIcons.table,
              color: themeData.colorScheme.primary,
              size: 20,
            ),
            onPressed: () => setState(() => showTableView = !showTableView),
            tooltip: safeTranslate('toggle_view', fallback: 'Toggle View'),
          ),
          IconButton(
            icon: Icon(
              FontAwesomeIcons.magnifyingGlass,
              color: themeData.colorScheme.primary,
              size: 20,
            ),
            onPressed: () {
              showSearchDialog(context);
            },
            tooltip: safeTranslate('search', fallback: 'Search'),
          ),
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
                    safeTranslate('coming_soon', fallback: 'Filters coming soon!'),
                    style:TextStyle(
                        fontFamily: 'Cairo',fontSize: 14),
                  ),
                ),
              );
            },
            tooltip: safeTranslate('filter', fallback: 'Filter'),
          ),
          IconButton(
            icon: Icon(
              FontAwesomeIcons.download,
              color: themeData.colorScheme.primary,
              size: 20,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    safeTranslate('coming_soon', fallback: 'Export coming soon!'),
                    style: TextStyle(
            fontFamily: 'Cairo',fontSize: 14),
                  ),
                ),
              );
            },
            tooltip: safeTranslate('export', fallback: 'Export'),
          ),
          SizedBox(width: MySize.size16!),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator(color: themeData.colorScheme.primary))
          : Padding(
        padding: EdgeInsets.all(MySize.size24!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            _SummaryCard(
              data: filteredData,
              themeData: themeData,
              safeTranslate: safeTranslate,
            ),
            SizedBox(height: MySize.size24!),
            // Header
            Text(
              safeTranslate('inventory_details', fallback: 'Inventory Details'),
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: themeData.colorScheme.primary,
              ),
            ),
            SizedBox(height: MySize.size8!),
            Text(
              safeTranslate('track_inventory_levels',
                  fallback: 'Track inventory levels'),
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: MySize.size16!),
            // Card or Table View
            Expanded(
              child: showTableView
                  ? _buildTableView(filteredData)
                  : _buildCardView(filteredData),
            ),
            // Pagination
            if (pageCount > 1)
              Padding(
                padding: EdgeInsets.symmetric(vertical: MySize.size16!),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: currentPage > 0
                          ? () => setState(() => currentPage--)
                          : null,
                    ),
                    Text(
                      '${safeTranslate('page', fallback: 'Page')} ${currentPage + 1} / $pageCount',
                      style: TextStyle(
            fontFamily: 'Cairo',fontSize: 16),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: currentPage < pageCount - 1
                          ? () => setState(() => currentPage++)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Card-based grid view
  Widget _buildCardView(List<ProductStockReportModel> data) {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, data.length);
    final pageData = data.sublist(startIndex, endIndex);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: MySize.size16!,
        mainAxisSpacing: MySize.size16!,
        childAspectRatio: 1.5,
      ),
      itemCount: pageData.length,
      itemBuilder: (context, index) {
        final item = pageData[index];
        return _ProductCard(
          item: item,
          themeData: themeData,
          safeTranslate: safeTranslate,
        );
      },
    );
  }

  // Enhanced table view
  Widget _buildTableView(List<ProductStockReportModel> data) {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, data.length);
    final pageData = data.sublist(startIndex, endIndex);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: MySize.size16!,
        headingRowColor: WidgetStatePropertyAll(themeData.colorScheme.primary.withAlpha((0.1 * 256).toInt())),
        dataRowColor: WidgetStatePropertyAll(Colors.white),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 256).toInt()),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        columns: [
          _buildColumn('product', 'Product'),
          _buildColumn('stock', 'Stock'),
          _buildColumn('total_sold', 'Total Sold'),
          _buildColumn('stock_price', 'Stock Price'),
          _buildColumn('sku', 'SKU'),
          _buildColumn('category_name', 'Category'),
          _buildColumn('location_nname', 'Location'),
          _buildColumn('alert_quantity', 'Alert Qty'),
          _buildColumn('unit', 'Unit'),
          _buildColumn('unit_pricee', 'Unit Price'),
          _buildColumn('type', 'Type'),
        ],
        rows: pageData.map((item) {
          return DataRow(
            cells: [
              DataCell(Text(item.product ?? '', style: textStyle(context))),
              DataCell(
                Text(
                  item.stock ?? '',
                  style: textStyle(context).copyWith(
                    color: (double.tryParse(item.stock ?? '0') ?? 0) <=
                        (double.tryParse(item.alertQuantity ?? '0') ?? 0)
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ),
              DataCell(Text(item.totalSold ?? '', style: textStyle(context))),
              DataCell(Text(item.stockPrice ?? '', style: textStyle(context))),
              DataCell(Text(item.sku ?? '', style: textStyle(context))),
              DataCell(Text(item.categoryName ?? '', style: textStyle(context))),
              DataCell(Text(item.locationName ?? '', style: textStyle(context))),
              DataCell(Text(item.alertQuantity ?? '', style: textStyle(context))),
              DataCell(Text(item.unit ?? '', style: textStyle(context))),
              DataCell(Text(item.unitPrice ?? '', style: textStyle(context))),
              DataCell(Text(item.type ?? '', style: textStyle(context))),
            ],
          );
        }).toList(),
      ),
    );
  }

  DataColumn _buildColumn(String key, String label) {
    return DataColumn(
      label: GestureDetector(
        onTap: () {
          setState(() {
            if (sortColumn == key) {
              sortAscending = !sortAscending;
            } else {
              sortColumn = key;
              sortAscending = true;
            }
          });
        },
        child: Row(
          children: [
            Text(
              safeTranslate(key, fallback: label),
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: themeData.colorScheme.primary,
              ),
            ),
            if (sortColumn == key)
              Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: themeData.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  // Search dialog
  void showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String tempQuery = searchQuery;
        return AlertDialog(
          title: Text(
            safeTranslate('search_products', fallback: 'Search Products'),
            style: TextStyle(
            fontFamily: 'Cairo',fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            decoration: InputDecoration(
              hintText: safeTranslate('search', fallback: 'Search by name, SKU...'),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => tempQuery = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(safeTranslate('cancel', fallback: 'Cancel')),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = tempQuery;
                  currentPage = 0;
                });
                Navigator.pop(context);
              },
              child: Text(safeTranslate('search', fallback: 'Search')),
            ),
          ],
        );
      },
    );
  }
}

// Summary card
class _SummaryCard extends StatelessWidget {
  final List<ProductStockReportModel> data;
  final ThemeData themeData;
  final String Function(String, {String fallback}) safeTranslate;

  const _SummaryCard({
    required this.data,
    required this.themeData,
    required this.safeTranslate,
  });

  @override
  Widget build(BuildContext context) {
    final totalProducts = data.length;
    final lowStock = data
        .where((item) =>
    (double.tryParse(item.stock ?? '0') ?? 0) <=
        (double.tryParse(item.alertQuantity ?? '0') ?? 0))
        .length;
    final totalStockValue = data.fold<double>(
      0,
          (sum, item) =>
      sum +
          ((double.tryParse(item.stock ?? '0') ?? 0) *
              (double.tryParse(item.unitPrice ?? '0') ?? 0)),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            themeData.colorScheme.secondary,
            themeData.colorScheme.secondary.withAlpha((0.7 * 256).toInt()),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 256).toInt()),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.all(MySize.size24!),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _MetricTile(
            icon: FontAwesomeIcons.boxesStacked,
            title: safeTranslate('total_products', fallback: 'Total Products'),
            value: totalProducts.toString(),
            color: Colors.white,
          ),
          _MetricTile(
            icon: FontAwesomeIcons.triangleExclamation,
            title: safeTranslate('low_stock', fallback: 'Low Stock'),
            value: lowStock.toString(),
            color: Colors.white,
          ),
          _MetricTile(
            icon: FontAwesomeIcons.dollarSign,
            title: safeTranslate('stock_value', fallback: 'Stock Value'),
            value: totalStockValue.toStringAsFixed(2),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

// Metric tile for summary card
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: MySize.size8!),
            Text(
              title,
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: MySize.size8!),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Product card
class _ProductCard extends StatefulWidget {
  final ProductStockReportModel item;
  final ThemeData themeData;
  final String Function(String, {String fallback}) safeTranslate;

  const _ProductCard({
    required this.item,
    required this.themeData,
    required this.safeTranslate,
  });

  @override
  __ProductCardState createState() => __ProductCardState();
}

class __ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLowStock = (double.tryParse(widget.item.stock ?? '0') ?? 0) <=
        (double.tryParse(widget.item.alertQuantity ?? '0') ?? 0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
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
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(MySize.size12!),
                  decoration: BoxDecoration(
                    color: widget.themeData.colorScheme.secondary.withAlpha((0.1 * 256).toInt()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FontAwesomeIcons.box,
                    size: 24,
                    color: widget.themeData.colorScheme.secondary,
                  ),
                ),
                SizedBox(width: MySize.size8!),
                Expanded(
                  child: Text(
                    widget.item.product ?? '',
                    style: TextStyle(
            fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: MySize.size8!),
            Text(
              '${widget.safeTranslate('stock', fallback: 'Stock')}: ${widget.item.stock ?? '0'}',
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 14,
                color: isLowStock ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.safeTranslate('total_sold', fallback: 'Total Sold')}: ${widget.item.totalSold ?? '0'}',
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '${widget.safeTranslate('category_name', fallback: 'Category')}: ${widget.item.categoryName ?? ''}',
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {
                  showDetailsDialog(context, widget.item);
                },
                child: Text(
                  widget.safeTranslate('view_details', fallback: 'View Details'),
                  style: TextStyle(
            fontFamily: 'Cairo',
                    fontSize: 14,
                    color: widget.themeData.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Details dialog
  void showDetailsDialog(BuildContext context, ProductStockReportModel item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            item.product ?? '',
            style: TextStyle(
            fontFamily: 'Cairo',fontSize: 20, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  label: widget.safeTranslate('sku', fallback: 'SKU'),
                  value: item.sku ?? '',
                ),
                _DetailRow(
                  label: widget.safeTranslate('stock', fallback: 'Stock'),
                  value: item.stock ?? '',
                  color: (double.tryParse(item.stock ?? '0') ?? 0) <=
                      (double.tryParse(item.alertQuantity ?? '0') ?? 0)
                      ? Colors.red
                      : Colors.green,
                ),
                _DetailRow(
                  label: widget.safeTranslate('total_sold', fallback: 'Total Sold'),
                  value: item.totalSold ?? '',
                ),
                _DetailRow(
                  label: widget.safeTranslate('stock_price', fallback: 'Stock Price'),
                  value: item.stockPrice ?? '',
                ),
                _DetailRow(
                  label: widget.safeTranslate('category_name', fallback: 'Category'),
                  value: item.categoryName ?? '',
                ),
                _DetailRow(
                  label: widget.safeTranslate('location_nname', fallback: 'Location'),
                  value: item.locationName ?? '',
                ),
                _DetailRow(
                  label: widget.safeTranslate('alert_quantity', fallback: 'Alert Quantity'),
                  value: item.alertQuantity ?? '',
                ),
                _DetailRow(
                  label: widget.safeTranslate('unit', fallback: 'Unit'),
                  value: item.unit ?? '',
                ),
                _DetailRow(
                  label: widget.safeTranslate('unit_pricee', fallback: 'Unit Price'),
                  value: item.unitPrice ?? '',
                ),
                _DetailRow(
                  label: widget.safeTranslate('type', fallback: 'Type'),
                  value: item.type ?? '',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                widget.safeTranslate('close', fallback: 'Close'),
                style: TextStyle(
            fontFamily: 'Cairo',
                  fontSize: 14,
                  color: widget.themeData.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Detail row for dialog
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DetailRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: MySize.size4!),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
            fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
            fontFamily: 'Cairo',
                fontSize: 14,
                color: color ?? Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle textStyle(BuildContext context) {
  return TextStyle(
            fontFamily: 'Cairo',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Theme.of(context).colorScheme.onSurface,
  );
}