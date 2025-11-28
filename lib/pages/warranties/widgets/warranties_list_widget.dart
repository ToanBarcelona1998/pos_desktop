import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/warranties/warranties_logic.dart';

class WarrantiesListWidget extends StatefulWidget {
  final WarrantiesLogic logic;

  const WarrantiesListWidget({super.key, required this.logic});

  @override
  _WarrantiesListWidgetState createState() => _WarrantiesListWidgetState();
}

class _WarrantiesListWidgetState extends State<WarrantiesListWidget> {
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
                  child: DropdownButtonFormField<String>(
                    value: widget.logic.filterDurationType,
                    hint: Text(localizations?.translate('filter_type') ?? 'فلتر النوع'),
                    items: ['day', 'month', 'year'].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(localizations?.translate(type) ?? type),
                      );
                    }).toList(),
                    onChanged: (value) => widget.logic.updateFilters(type: value),
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
                    width: constraints.maxWidth,  // تقييد العرض لتجنب infinite width
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                      dataRowHeight: 56,
                      columns: [
                        DataColumn(label: Text(localizations?.translate('name') ?? 'الاسم')),
                        DataColumn(label: Text(localizations?.translate('description') ?? 'الوصف')),
                        DataColumn(label: Text(localizations?.translate('duration') ?? 'المدة')),
                        DataColumn(label: Text(localizations?.translate('duration_type') ?? 'النوع')),
                        DataColumn(label: Text(localizations?.translate('linked_products') ?? 'المنتجات المرتبطة')),
                        DataColumn(label: Text(localizations?.translate('actions') ?? 'الإجراءات')),
                      ],
                      rows: widget.logic.filteredWarranties.map((warranty) {
                        return DataRow(cells: [
                          DataCell(Text(warranty['name'] ?? '')),
                          DataCell(Text(warranty['description'] ?? 'غير متوفر')),
                          DataCell(Text(warranty['duration'].toString())),
                          DataCell(Text(warranty['duration_type'] ?? '')),
                          DataCell(Text((warranty['linked_products_count'] ?? 0).toString())),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.edit, color: Colors.blue),
                                onPressed: () => widget.logic.showWarrantyFormDialog(context, isEdit: true, warranty: warranty),
                                tooltip: 'تعديل',
                              ),
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.trash, color: Colors.red),
                                onPressed: () => _confirmDelete(context, warranty['id']),
                                tooltip: 'حذف',
                              ),
                              IconButton(
                                icon: const Icon(FontAwesomeIcons.infoCircle, color: Colors.green),
                                onPressed: () => widget.logic.showWarrantyDetails(context, warranty),
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
              widget.logic.deleteWarranty(id);
            },
            child: Text(localizations?.translate('delete') ?? 'نعم'),
          ),
        ],
      ),
    );
  }
}