import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_table_row.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Read-only copy of the form fields for one staged scan (Scanned Docket Details).
class HubScanSessionCard extends StatelessWidget {
  const HubScanSessionCard({
    super.key,
    required this.row,
    required this.branchLabel,
    this.onRemove,
  });

  final HubScanTableRow row;
  final String Function(String? id) branchLabel;
  final VoidCallback? onRemove;

  String _v(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return '—';
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final branch = row.branchId != null ? branchLabel(row.branchId) : '—';
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: 10.h),
      color: row.saved
          ? themes.lightGrayColor.withValues(alpha: 0.35)
          : themes.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.r),
        side: BorderSide(
          color: row.saved
              ? themes.grayColor.withValues(alpha: 0.3)
              : themes.darkCyanBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _v(row.docketNo),
                    style: themes.fontSize14_500.copyWith(
                      color: themes.darkCyanBlue,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: row.saved
                        ? themes.grayColor.withValues(alpha: 0.25)
                        : themes.darkCyanBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    row.saved ? 'Saved' : 'Pending save',
                    style: themes.fontSize14_400.copyWith(
                      fontSize: 11.sp,
                      color: row.saved ? themes.grayColor : themes.darkCyanBlue,
                    ),
                  ),
                ),
                if (!row.saved && onRemove != null) ...[
                  SizedBox(width: 4.w),
                  IconButton(
                    onPressed: onRemove,
                    icon: Icon(Icons.close, color: themes.redColor, size: 22.sp),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.w),
                    tooltip: 'Remove',
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 6.h),
            _line(OutboundLabels.scanType, _v(row.scanType)),
            _line(OutboundLabels.branchHub, branch),
            _line(OutboundLabels.clientCode, _v(row.clientCode)),
            _line(OutboundLabels.noOfBox, _v(row.noOfBox)),
            _line(OutboundLabels.boxWeight, _v(row.boxWeight)),
            _line(OutboundLabels.originPincode, _v(row.originPincode)),
            _line(OutboundLabels.destPincode, _v(row.destPincode)),
            _line(OutboundLabels.destCity, _v(row.destCity)),
            if (_v(row.receiver) != '—')
              _line(OutboundLabels.receiverName, _v(row.receiver)),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118.w,
            child: Text(
              '$label :',
              style: themes.fontSize14_400.copyWith(color: themes.grayColor),
            ),
          ),
          Expanded(
            child: Text(value, style: themes.fontSize14_500),
          ),
        ],
      ),
    );
  }
}
