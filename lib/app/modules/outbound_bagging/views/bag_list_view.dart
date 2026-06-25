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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// `listbags` — filtered by origin `branch_id` from the bagging screen.
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
      final filterNote = controller.selectedDepotSummary;

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
              if (filterNote.isNotEmpty)
                Text(
                  filterNote,
                  style:
                      themes.fontSize14_400.copyWith(color: themes.grayColor),
                ),
              if (loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: themes.darkCyanBlue),
                  ),
                )
              else if (err.isNotEmpty)
                _ListMessage(
                  text: err,
                  onRetry: controller.loadBagList,
                )
              else if (rows.isEmpty)
                const _ListMessage(text: OutboundLabels.bagListEmptyMessage)
              else ...[
                Text(
                  rangeLabel,
                  style:
                      themes.fontSize14_400.copyWith(color: themes.grayColor),
                ),
                _BagListTable(
                  rows: rows,
                  rowOffset: controller.bagListRowNumberOffset,
                  branchLabel: branchList.displayLabelForId,
                  onTap: controller.openBagDetailsFromList,
                  onRebag: (row) => controller.showRebagDialog(
                    defaultNewBagCode: row.bagCode,
                  ),
                  onCopy: _copyBagCode,
                ),
                if (totalPages > 1) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Page $page of $totalPages',
                    textAlign: TextAlign.center,
                    style:
                        themes.fontSize14_400.copyWith(color: themes.grayColor),
                  ),
                  SizedBox(height: 8.h),
                  OutboundButtonRow(
                    start: OutboundSecondaryButton(
                      label: 'Previous',
                      onPressed:
                          page > 1 ? controller.bagListPreviousPage : null,
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
    required this.onRebag,
    required this.onCopy,
  });

  final List<OutboundBagRow> rows;
  final int rowOffset;
  final String Function(String? id) branchLabel;
  final void Function(OutboundBagRow row) onTap;
  final void Function(OutboundBagRow row) onRebag;
  final void Function(String? bagCode) onCopy;

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
          showCheckboxColumn: false,
          headingRowHeight: 44,
          dataRowMinHeight: 48,
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 11.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text(OutboundLabels.colSlNo)),
            DataColumn(label: Text(OutboundLabels.bagCode)),
            DataColumn(label: Text(OutboundLabels.metalSeal)),
            DataColumn(label: Text(OutboundLabels.colOrigin)),
            DataColumn(label: Text(OutboundLabels.colDestination)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(
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
                  DataCell(Text(branchLabel(rows[i].originBranchId))),
                  DataCell(
                    Text(
                      branchLabel(
                        rows[i].destinationSectorId ??
                            rows[i].destinationBranchId,
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutboundTableTextLink(
                          label: OutboundLabels.btnView,
                          onPressed: () => onTap(rows[i]),
                        ),
                        IconButton(
                          tooltip: OutboundLabels.btnCopy,
                          onPressed: () => onCopy(rows[i].bagCode),
                          icon: Icon(
                            Icons.copy_outlined,
                            size: 18.sp,
                            color: themes.darkCyanBlue,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onRebag(rows[i]),
                          child: Text(OutboundLabels.btnRebag),
                        ),
                      ],
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

Future<void> _copyBagCode(String? bagCode) async {
  final code = bagCode?.trim();
  if (code == null || code.isEmpty) return;
  await Clipboard.setData(ClipboardData(text: code));
  Get.snackbar('Bagging', 'Bag code copied.');
}

class _ListMessage extends StatelessWidget {
  const _ListMessage({required this.text, this.onRetry});

  final String text;
  final Future<bool> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: themes.fontSize14_400.copyWith(color: themes.grayColor),
        ),
        if (onRetry != null) ...[
          SizedBox(height: 12.h),
          OutboundSecondaryButton(
            label: 'Retry',
            onPressed: () => onRetry!(),
          ),
        ],
      ],
    );
  }
}
