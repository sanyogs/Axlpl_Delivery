import 'package:axlpl_delivery/app/data/models/outbound/bagging_table_row.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_copyable.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Admin **Scanned Box Details** table (horizontal scroll).
class BaggingScannedBoxTable extends StatelessWidget {
  const BaggingScannedBoxTable({
    super.key,
    required this.rows,
    this.onRemove,
  });

  final List<BaggingTableRow> rows;
  final void Function(BaggingTableRow row)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No boxes scanned yet.',
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: themes.grayColor.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 64,
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 11.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text(OutboundLabels.colSlNo)),
            DataColumn(label: Text(OutboundLabels.bagCode)),
            DataColumn(label: Text(OutboundLabels.colBoxNumber)),
            DataColumn(label: Text(OutboundLabels.colShipmentId)),
            DataColumn(label: Text(OutboundLabels.colDestination)),
            DataColumn(label: Text(OutboundLabels.colMode)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              _dataRow(index: i + 1, row: rows[i]),
          ],
        ),
      ),
    );
  }

  DataRow _dataRow({required int index, required BaggingTableRow row}) {
    final stripe = index.isEven
        ? themes.lightGrayColor.withValues(alpha: 0.35)
        : themes.whiteColor;
    String cell(String? v) {
      final t = v?.trim();
      if (t == null || t.isEmpty) return '—';
      return t;
    }

    return DataRow(
      color: WidgetStateProperty.all(stripe),
      cells: [
        DataCell(Text('$index', style: themes.fontSize14_400)),
        DataCell(
          OutboundCopyableTableCell(
            value: row.bagCode,
            snackbarTitle: 'Bagging',
          ),
        ),
        DataCell(
          OutboundCopyableTableCell(
            value: row.boxNumber,
            snackbarTitle: 'Bagging',
          ),
        ),
        DataCell(
          OutboundCopyableTableCell(
            value: row.shipmentId,
            emphasized: true,
            snackbarTitle: 'Bagging',
          ),
        ),
        DataCell(Text(cell(row.destination), style: themes.fontSize14_400)),
        DataCell(Text(cell(row.mode), style: themes.fontSize14_400)),
        DataCell(
          onRemove == null
              ? const SizedBox.shrink()
              : IconButton(
                  onPressed: () => onRemove!(row),
                  icon: Icon(Icons.delete_outline,
                      color: themes.redColor, size: 22.sp),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
                  tooltip: 'Remove',
                ),
        ),
      ],
    );
  }
}
