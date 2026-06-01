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
    final statusColor = row.saved ? Colors.green.shade700 : themes.darkCyanBlue;
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
        padding: EdgeInsets.all(10.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    color: themes.darkCyanBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 20.sp,
                    color: themes.darkCyanBlue,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Docket',
                        style: themes.fontSize14_400.copyWith(
                          color: themes.grayColor,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _v(row.docketNo),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: themes.fontSize18_600.copyWith(
                          color: themes.darkCyanBlue,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: row.saved ? 'Saved' : 'Pending',
                  color: statusColor,
                ),
                if (!row.saved && onRemove != null) ...[
                  SizedBox(width: 6.w),
                  _RemoveScanButton(onPressed: onRemove!),
                ],
              ],
            ),
            SizedBox(height: 10.h),
            Container(
              decoration: BoxDecoration(
                color: themes.lightGrayColor.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(5.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Column(
                children: [
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
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112.w,
            child: Text(
              '$label :',
              style: themes.fontSize14_400.copyWith(
                color: themes.grayColor,
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themes.fontSize14_500.copyWith(fontSize: 12.5.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            label,
            style: themes.fontSize14_500.copyWith(
              color: color,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveScanButton extends StatelessWidget {
  const _RemoveScanButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34.w,
      height: 34.w,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(34.w, 34.w),
          foregroundColor: themes.redColor,
          side: BorderSide(color: themes.redColor.withValues(alpha: 0.35)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.r)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Icon(Icons.delete_outline, size: 18.sp),
      ),
    );
  }
}
