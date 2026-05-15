import 'package:flutter/material.dart';

/// Scrollable [DataTable] for unknown JSON list rows (bags / manifests / linehauls).
class OutboundDynamicMapTable extends StatelessWidget {
  const OutboundDynamicMapTable({
    super.key,
    required this.rows,
    this.title = 'List preview',
    this.maxColumns = 7,
    this.onRowTap,
  });

  final List<Map<String, dynamic>> rows;
  final String title;
  final int maxColumns;
  final void Function(Map<String, dynamic> row)? onRowTap;

  static List<String> _columnKeys(List<Map<String, dynamic>> rows, int max) {
    final keys = <String>{};
    for (final r in rows.take(25)) {
      keys.addAll(r.keys.map((k) => k.toString()));
    }
    final sorted = keys.toList()..sort();
    return sorted.take(max).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final cols = _columnKeys(rows, maxColumns);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 64,
            columns: cols
                .map((c) => DataColumn(label: Text(c, maxLines: 1)))
                .toList(),
            rows: rows.map((row) {
              return DataRow(
                onSelectChanged: onRowTap == null
                    ? null
                    : (_) => onRowTap!(row),
                cells: cols
                    .map((c) => DataCell(Text('${row[c] ?? ''}')))
                    .toList(),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
