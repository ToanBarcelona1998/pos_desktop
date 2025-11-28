import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/brands/brands_logic.dart';

class BrandsListWidget extends StatefulWidget {
  final BrandsLogic logic;

  const BrandsListWidget({super.key, required this.logic});

  @override
  _BrandsListWidgetState createState() => _BrandsListWidgetState();
}

class _BrandsListWidgetState extends State<BrandsListWidget> {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: widget.logic.searchController,
                    decoration: InputDecoration(
                      labelText: localizations?.translate('search') ?? 'بحث',
                      prefixIcon: const Icon(FontAwesomeIcons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<bool?>(
                    value: widget.logic.filterUseForRepair,
                    hint: Text(localizations?.translate('filter_use_for_repair') ?? 'فلتر استخدام للإصلاح'),
                    items: [
                      DropdownMenuItem<bool?>(value: null, child: Text(localizations?.translate('all') ?? 'الكل')),
                      DropdownMenuItem<bool>(value: true, child: Text(localizations?.translate('yes') ?? 'نعم')),
                      DropdownMenuItem<bool>(value: false, child: Text(localizations?.translate('no') ?? 'لا')),
                    ],
                    onChanged: (value) => widget.logic.updateFilters(useForRepair: value),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(FontAwesomeIcons.fileCsv, color: Colors.green),
                  onPressed: widget.logic.exportToCSV,
                  tooltip: localizations?.translate('export_csv') ?? 'تصدير إلى CSV',
                ),
              ],
            ),
            const SizedBox(height: 24),
            widget.logic.isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                      dataRowHeight: 56,
                      columns: [
                        DataColumn(label: Text(localizations?.translate('brand_name') ?? 'الاسم')),
                        DataColumn(label: Text(localizations?.translate('short_description') ?? 'الوصف')),
                        DataColumn(label: Text(localizations?.translate('use_for_repair') ?? 'استخدام للإصلاح')),
                        DataColumn(label: Text(localizations?.translate('linked_products_count') ?? 'المنتجات المرتبطة')),
                        DataColumn(label: Text(localizations?.translate('actions') ?? 'الإجراءات')),
                      ],
                      rows: widget.logic.filteredBrands.map((brand) {
                        return DataRow(cells: [
                          DataCell(Text(brand['name'] ?? '')),
                          DataCell(Text(brand['description'] ?? 'غير متوفر')),
                          DataCell(Text(brand['use_for_repair'] == 1 ? 'نعم' : 'لا')),
                          DataCell(Text((brand['linked_products_count'] ?? 0).toString())),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.edit, color: Colors.blue),
                                onPressed: () => widget.logic.showBrandFormDialog(context, isEdit: true, brand: brand),
                                tooltip: 'تعديل',
                              ),
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
                                onPressed: () => _confirmDelete(context, brand['id']),
                                tooltip: 'حذف',
                              ),
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.infoCircle, color: Colors.green),
                                onPressed: () => widget.logic.showBrandDetails(context, brand),
                                tooltip: 'تفاصيل',
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    final localizations = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(localizations?.translate('confirm') ?? 'تأكيد'),
        content: Text(localizations?.translate('are_you_sure_delete') ?? 'هل أنت متأكد من الحذف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations?.translate('cancel') ?? 'إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.logic.deleteBrand(id);
            },
            child: Text(localizations?.translate('yes') ?? 'نعم'),
          ),
        ],
      ),
    );
  }
}