import 'package:flutter/material.dart';
import 'package:pos_final/locale/my_localizations.dart';
import 'package:provider/provider.dart';
import 'package:table_sticky_headers/table_sticky_headers.dart';

class FixedHeaderDataTableWidget extends StatelessWidget {
  const FixedHeaderDataTableWidget(
      {super.key, required this.columns, required this.cells});

  final List<String> columns;
  final List<List<String>> cells;

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(
          top: 8,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.35,
          decoration: BoxDecoration(
              color: Theme.of(context).focusColor,
              borderRadius: BorderRadius.circular(12)),
          child: StickyHeadersTable(
            columnsLength: columns.length,
            tableDirection:
                (Provider.of<AppLanguage>(context, listen: false).appLocal ==
                        const Locale('en'))
                    ? TextDirection.ltr
                    : TextDirection.rtl,
            rowsLength: cells.length,
            columnsTitleBuilder: (columnIndex) => Text(
              columns[columnIndex],
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            contentCellBuilder: (columnIndex, rowIndex) => Text(
              cells[rowIndex][columnIndex],
            ),
            rowsTitleBuilder: (int rowIndex) => Text((rowIndex + 1).toString()),
            legendCell: const Text('#',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )),
            cellDimensions: const CellDimensions.fixed(
              contentCellWidth: 70.0,
              contentCellHeight: 50.0,
              stickyLegendWidth: 50.0,
              stickyLegendHeight: 50.0,
            ),
          ),
        ));
  }
}
