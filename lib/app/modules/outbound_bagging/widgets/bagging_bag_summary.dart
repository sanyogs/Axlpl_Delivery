import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Read-only summary from `getbagdetails` response (no dummy values).
class BaggingBagSummary extends StatelessWidget {
  const BaggingBagSummary({super.key, required this.detail});

  final BagDetail detail;

  @override
  Widget build(BuildContext context) {
    final branchList = Get.find<OutboundBranchListController>();
    final origin = _branchLabel(
      branchList,
      detail.originBranchName,
      detail.originBranchId,
    );
    final destination = _branchLabel(
      branchList,
      detail.destinationSectorName,
      detail.destinationSectorId,
    );
    final count = detail.shipmentCount ?? detail.items.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutboundDetailField(
          label: OutboundLabels.bagCode,
          value: detail.bagCode ?? '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.metalSeal,
          value: detail.metalSealNo ?? '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.manifestStatus,
          value: detail.manifestStatus ?? '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.shipmentCount,
          value: '$count',
        ),
        OutboundDetailField(
          label: OutboundLabels.originDepot,
          value: origin,
        ),
        OutboundDetailField(
          label: OutboundLabels.destinationDepot,
          value: destination,
        ),
        if (detail.createdAt != null && detail.createdAt!.isNotEmpty)
          OutboundDetailField(
            label: OutboundLabels.created,
            value: detail.createdAt!,
          ),
      ],
    );
  }

  static String _branchLabel(
    OutboundBranchListController branchList,
    String? name,
    String? id,
  ) {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (id != null && id.trim().isNotEmpty) {
      return branchList.displayLabelForId(id.trim());
    }
    return '—';
  }
}

/// Compact banner when bag exists but full summary is below the fold.
class BaggingBagSummaryBanner extends StatelessWidget {
  const BaggingBagSummaryBanner({
    super.key,
    required this.detail,
    this.onCopy,
  });

  final BagDetail detail;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final code = detail.bagCode?.trim();
    final status = detail.manifestStatus?.trim();
    final count = detail.shipmentCount ?? detail.items.length;
    if (code == null || code.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: themes.lightGrayColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$code · ${status ?? '—'} · $count shipment(s)',
              style: themes.fontSize14_500.copyWith(color: themes.darkCyanBlue),
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: Icon(
              Icons.copy_outlined,
              size: 18.sp,
              color: themes.darkCyanBlue,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: OutboundLabels.btnCopy,
          ),
        ],
      ),
    );
  }
}
