import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Scrollable table for bag / manifest / linehaul list rows.
class OutboundDynamicMapTable extends StatelessWidget {
  const OutboundDynamicMapTable({
    super.key,
    required this.rows,
    this.title = 'List preview',
    this.maxColumns = 6,
    this.onRowTap,
    this.emptyHint,
  });

  final List<Map<String, dynamic>> rows;
  final String title;
  final int maxColumns;
  final void Function(Map<String, dynamic> row)? onRowTap;
  final String? emptyHint;

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
    if (rows.isEmpty) {
      return Text(
        emptyHint ?? 'No rows — run list action above.',
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
    final cols = _columnKeys(rows, maxColumns);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: themes.fontSize14_500),
        SizedBox(height: 8.h),
        Card(
          elevation: 0,
          color: themes.whiteColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: DataTable(
              headingRowHeight: 40,
              dataRowMinHeight: 40,
              dataRowMaxHeight: 56,
              headingTextStyle: themes.fontSize14_500,
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
        ),
        if (onRowTap != null)
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Text(
              'Tap a row to fill the field above.',
              style: themes.fontSize14_400.copyWith(color: themes.grayColor),
            ),
          ),
      ],
    );
  }
}
