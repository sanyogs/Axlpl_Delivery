import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_log_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Admin hub-scan history table (horizontal scroll — same pattern as manifest lists).
class HubScanHistoryTable extends StatelessWidget {
  const HubScanHistoryTable({
    super.key,
    required this.rows,
    required this.branchLabel,
    this.rowNumberOffset = 0,
    this.onView,
    this.onPrint,
  });

  final List<HubScanLog> rows;
  final String Function(String? id) branchLabel;
  final int rowNumberOffset;
  final void Function(HubScanLog row)? onView;
  final void Function(HubScanLog row)? onPrint;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No hub scans for this branch.',
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
            DataColumn(label: Text(OutboundLabels.colShipmentDocket)),
            DataColumn(label: Text(OutboundLabels.colScanType)),
            DataColumn(label: Text(OutboundLabels.colScannedAt)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              _dataRow(
                context,
                index: rowNumberOffset + i + 1,
                row: rows[i],
              ),
          ],
        ),
      ),
    );
  }

  DataRow _dataRow(
    BuildContext context, {
    required int index,
    required HubScanLog row,
  }) {
    final stripe = index.isEven
        ? themes.lightGrayColor.withValues(alpha: 0.35)
        : themes.whiteColor;
    final scanType = row.scanTypeDisplay(null);

    return DataRow(
      color: WidgetStateProperty.all(stripe),
      cells: [
        DataCell(Text('$index', style: themes.fontSize14_400)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16.sp,
                color: themes.darkCyanBlue,
              ),
              SizedBox(width: 4.w),
              Text(
                row.docketDisplay,
                style: themes.fontSize14_500.copyWith(color: themes.darkCyanBlue),
              ),
            ],
          ),
        ),
        DataCell(Text(scanType, style: themes.fontSize14_400)),
        DataCell(
          Text(
            row.scannedAtDisplay,
            style: themes.fontSize14_400,
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionIcon(
                icon: Icons.visibility_outlined,
                tooltip: 'View',
                onPressed: onView == null ? null : () => onView!(row),
              ),
              SizedBox(width: 4.w),
              _ActionIcon(
                icon: Icons.print_outlined,
                tooltip: 'Print',
                onPressed: onPrint == null ? null : () => onPrint!(row),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32.w,
      height: 32.w,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(32.w, 32.w),
          side: BorderSide(color: themes.grayColor.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
          foregroundColor: themes.darkCyanBlue,
        ),
        child: Icon(icon, size: 16.sp),
      ),
    );
  }
}

/// Full row detail — all API fields (admin view dialog).
void showHubScanLogDetail(
  BuildContext context, {
  required HubScanLog row,
  required String Function(String? id) branchLabel,
}) {
  final branch = HubScanLog.branchDisplay(row.branchId, branchLabel);
  final scanType = row.scanTypeDisplay(null);

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        row.docketDisplay,
        style: themes.fontSize18_600,
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            OutboundDetailField(
              label: OutboundLabels.colShipmentDocket,
              value: row.docketDisplay,
            ),
            OutboundDetailField(
              label: OutboundLabels.hubScanShipmentId,
              value: row.shipmentId ?? '—',
            ),
            OutboundDetailField(
              label: OutboundLabels.colScanType,
              value: scanType,
            ),
            OutboundDetailField(
              label: OutboundLabels.colBranchHub,
              value: branch,
            ),
            OutboundDetailField(
              label: OutboundLabels.colScannedAt,
              value: row.scannedAtDisplay,
            ),
            OutboundDetailField(
              label: OutboundLabels.hubScanLogId,
              value: row.id ?? '—',
            ),
            OutboundDetailField(
              label: OutboundLabels.hubScanBoxNo,
              value: row.boxNo ?? '—',
            ),
            OutboundDetailField(
              label: OutboundLabels.created,
              value: row.createdAtDisplay,
            ),
            OutboundDetailField(
              label: OutboundLabels.updated,
              value: row.updatedAtDisplay,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Close',
            style: themes.fontSize14_500.copyWith(color: themes.darkCyanBlue),
          ),
        ),
      ],
    ),
  );
}
