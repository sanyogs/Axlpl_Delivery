import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/controllers/outbound_hub_scan_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/widgets/hub_scan_history_table.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin **Hub Scan List** — saved history (`gethubscanlogs`), all rows, paged.
class HubScanListView extends StatefulWidget {
  const HubScanListView({super.key});

  @override
  State<HubScanListView> createState() => _HubScanListViewState();
}

class _HubScanListViewState extends State<HubScanListView> {
  late final OutboundHubScanController controller;
  late final OutboundBranchListController branchList;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundHubScanController>();
    branchList = Get.find<OutboundBranchListController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadHubScanList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isHubScanListLoading.value;
      final err = controller.hubScanListError.value.trim();
      final rows = controller.hubScanListPageRows;
      final branchLabel = branchList.displayLabelForId;
      final page = controller.hubScanListPage.value;
      final totalPages = controller.hubScanListTotalPages;
      final rangeLabel = controller.hubScanListRangeLabel;
      final allBranches = controller.hubScanListShowsAllBranches;
      final _ = controller.hubScanListAllRows.length;

      return OutboundScreen(
        title: OutboundLabels.hubScanListTitle,
        busy: false,
        onRefresh: loading
            ? null
            : () async {
                await controller.loadHubScanList();
              },
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnPerformScan,
              onPressed: () => Get.back(),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.hubScanHistory,
            trailing: _NewHubScanHeaderButton(
              enabled: true,
              onPressed: () => Get.back(),
            ),
            children: [
              if (loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: themes.darkCyanBlue,
                    ),
                  ),
                )
              else if (err.isNotEmpty)
                _ListMessage(
                  text: err,
                  onRetry: controller.loadHubScanList,
                )
              else if (rows.isEmpty)
                _ListMessage(
                  text: 'No hub scans found.',
                  onRetry: controller.loadHubScanList,
                )
              else ...[
                if (allBranches)
                  Text(
                    'All branches',
                    style: themes.fontSize14_500.copyWith(
                      color: themes.darkCyanBlue,
                    ),
                  ),
                Text(
                  rangeLabel,
                  style: themes.fontSize14_400.copyWith(color: themes.grayColor),
                ),
                HubScanHistoryTable(
                  rows: rows,
                  branchLabel: branchLabel,
                  rowNumberOffset: controller.hubScanListRowNumberOffset,
                  onView: (row) => showHubScanLogDetail(
                    context,
                    row: row,
                    branchLabel: branchLabel,
                  ),
                  onPrint: (row) {
                    Get.snackbar(
                      'Hub scan',
                      'Print for ${row.docketDisplay} — use admin web for label print.',
                    );
                  },
                ),
                if (totalPages > 1) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Page $page of $totalPages',
                    textAlign: TextAlign.center,
                    style: themes.fontSize14_400.copyWith(color: themes.grayColor),
                  ),
                  SizedBox(height: 8.h),
                  _HubScanListPagination(
                    page: page,
                    totalPages: totalPages,
                    onPrevious: controller.hubScanListPreviousPage,
                    onNext: controller.hubScanListNextPage,
                  ),
                ],
              ],
            ],
          ),
        ],
      );
    });
  }
}

class _HubScanListPagination extends StatelessWidget {
  const _HubScanListPagination({
    required this.page,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return OutboundButtonRow(
      start: OutboundSecondaryButton(
        label: 'Previous',
        onPressed: page > 1 ? onPrevious : null,
      ),
      end: OutboundSecondaryButton(
        label: 'Next',
        onPressed: page < totalPages ? onNext : null,
      ),
    );
  }
}

class _NewHubScanHeaderButton extends StatelessWidget {
  const _NewHubScanHeaderButton({
    required this.onPressed,
    required this.enabled,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        backgroundColor: themes.whiteColor,
        foregroundColor: themes.darkCyanBlue,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(Icons.add, size: 16.sp, color: themes.darkCyanBlue),
      label: Text(
        OutboundLabels.btnNewHubScan,
        style: themes.fontSize14_500.copyWith(
          fontSize: 11.sp,
          color: themes.darkCyanBlue,
        ),
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({
    required this.text,
    required this.onRetry,
  });

  final String text;
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: themes.fontSize14_400.copyWith(color: themes.grayColor),
        ),
        SizedBox(height: 12.h),
        OutboundSecondaryButton(
          label: 'Retry',
          onPressed: () => onRetry(),
        ),
      ],
    );
  }
}
