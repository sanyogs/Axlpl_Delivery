import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin **Show List** — bags at origin depot (`listbags`).
class BagListView extends StatefulWidget {
  const BagListView({super.key});

  @override
  State<BagListView> createState() => _BagListViewState();
}

class _BagListViewState extends State<BagListView> {
  late final OutboundBaggingController controller;
  late final OutboundBranchListController branchList;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundBaggingController>();
    branchList = Get.find<OutboundBranchListController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadBagList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isBagListLoading.value;
      final err = controller.bagListError.value.trim();
      final rows = controller.bagListPageRows;
      final page = controller.bagListPage.value;
      final totalPages = controller.bagListTotalPages;
      final rangeLabel = controller.bagListRangeLabel;
      final _ = '${controller.bagListFilteredRows.length}|${controller.bagListAllRows.length}';

      return OutboundScreen(
        title: OutboundLabels.bagListTitle,
        busy: false,
        onRefresh: loading
            ? null
            : () async {
                await controller.loadBagList();
              },
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnPerformBagging,
              onPressed: () => Get.back(),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.bagListTitle,
            trailing: TextButton.icon(
              onPressed: () => Get.back(),
              style: TextButton.styleFrom(
                backgroundColor: themes.whiteColor,
                foregroundColor: themes.darkCyanBlue,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.add, size: 16.sp, color: themes.darkCyanBlue),
              label: Text(
                OutboundLabels.btnNewBagging,
                style: themes.fontSize14_500.copyWith(
                  fontSize: 11.sp,
                  color: themes.darkCyanBlue,
                ),
              ),
            ),
            children: [
              if (loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: CircularProgressIndicator(color: themes.darkCyanBlue),
                  ),
                )
              else if (err.isNotEmpty)
                _ListMessage(text: err, onRetry: controller.loadBagList)
              else if (rows.isEmpty)
                _ListMessage(
                  text: 'No bags found.',
                  onRetry: controller.loadBagList,
                )
              else ...[
                Text(
                  rangeLabel,
                  style: themes.fontSize14_400.copyWith(color: themes.grayColor),
                ),
                _BagListTable(
                  rows: rows,
                  rowOffset: controller.bagListRowNumberOffset,
                  branchLabel: branchList.displayLabelForId,
                  onTap: controller.applyBagFromList,
                ),
                if (totalPages > 1) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Page $page of $totalPages',
                    textAlign: TextAlign.center,
                    style: themes.fontSize14_400.copyWith(color: themes.grayColor),
                  ),
                  SizedBox(height: 8.h),
                  OutboundButtonRow(
                    start: OutboundSecondaryButton(
                      label: 'Previous',
                      onPressed: page > 1 ? controller.bagListPreviousPage : null,
                    ),
                    end: OutboundSecondaryButton(
                      label: 'Next',
                      onPressed:
                          page < totalPages ? controller.bagListNextPage : null,
                    ),
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

class _BagListTable extends StatelessWidget {
  const _BagListTable({
    required this.rows,
    required this.rowOffset,
    required this.branchLabel,
    required this.onTap,
  });

  final List<OutboundBagRow> rows;
  final int rowOffset;
  final String Function(String? id) branchLabel;
  final void Function(OutboundBagRow row) onTap;

  @override
  Widget build(BuildContext context) {
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
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 11.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text(OutboundLabels.colSlNo)),
            DataColumn(label: Text('BAG CODE')),
            DataColumn(label: Text('METAL SEAL')),
            DataColumn(label: Text('DESTINATION')),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(
                onSelectChanged: (_) => onTap(rows[i]),
                cells: [
                  DataCell(Text('${rowOffset + i + 1}')),
                  DataCell(
                    Text(
                      rows[i].bagCode ?? '—',
                      style: themes.fontSize14_500.copyWith(
                        color: themes.darkCyanBlue,
                      ),
                    ),
                  ),
                  DataCell(Text(rows[i].metalSealNo ?? '—')),
                  DataCell(Text(branchLabel(rows[i].destinationBranchId))),
                  DataCell(
                    TextButton(
                      onPressed: () => onTap(rows[i]),
                      child: const Text('Open'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({required this.text, required this.onRetry});

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
