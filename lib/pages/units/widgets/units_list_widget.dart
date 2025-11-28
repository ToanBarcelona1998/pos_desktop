import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:pos_final/pages/units/units_logic.dart';

class UnitsListWidget extends StatelessWidget {
  final UnitsLogic logic;

  const UnitsListWidget({super.key, required this.logic});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations?.translate('units_list') ?? 'Units List',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: logic.searchController,
              decoration: InputDecoration(
                labelText: localizations?.translate('search') ?? 'Search',
                prefixIcon: Icon(FontAwesomeIcons.search, color: theme.colorScheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
            const SizedBox(height: 16),
            logic.isLoading
                ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                headingRowColor: WidgetStateProperty.all(theme.colorScheme.primary.withOpacity(0.1)),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? theme.colorScheme.primary.withOpacity(0.2)
                      : null;
                }),
                columns: [
                  DataColumn(
                    label: Text(
                      localizations?.translate('actual_name') ?? 'Name',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      localizations?.translate('short_name') ?? 'Short Name',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      localizations?.translate('allow_decimal') ?? 'Decimal',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      localizations?.translate('base_unit') ?? 'Base Unit',
                      style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
                    ),
                  ),
                  const DataColumn(label: Text('Actions', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600))),
                ],
                rows: logic.filteredUnits.asMap().entries.map((entry) {
                  final index = entry.key;
                  final unit = entry.value;
                  return DataRow(
                    color: WidgetStateProperty.all(
                      index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                    ),
                    cells: [
                      DataCell(Text(unit['actual_name'] ?? '')),
                      DataCell(Text(unit['short_name'] ?? '')),
                      DataCell(Text(unit['allow_decimal'] == 1 ? 'Yes' : 'No')),
                      DataCell(Text(unit['base_unit']?['actual_name'] ?? 'N/A')),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(FontAwesomeIcons.edit, color: theme.colorScheme.primary),
                            onPressed: () => logic.showUnitFormDialog(context, isEdit: true, unit: unit),
                            tooltip: localizations?.translate('edit') ?? 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(FontAwesomeIcons.trash, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(context, unit['id']),
                            tooltip: localizations?.translate('delete') ?? 'Delete',
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
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
        title: Text(
          localizations?.translate('confirm') ?? 'Confirm',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
        ),
        content: Text(
          localizations?.translate('are_you_sure_delete') ?? 'Are you sure?',
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(localizations?.translate('no') ?? 'No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              logic.deleteUnit(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(localizations?.translate('yes') ?? 'Yes'),
          ),
        ],
      ),
    );
  }
}