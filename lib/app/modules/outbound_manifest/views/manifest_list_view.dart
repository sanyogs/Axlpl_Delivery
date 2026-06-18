import 'package:axlpl_delivery/app/data/models/outbound/outbound_manifest_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_response_panel.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_manifest/controllers/outbound_manifest_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// `listmanifests` — filtered by origin `branch_id` from the manifest screen.
class ManifestListView extends StatefulWidget {
  const ManifestListView({super.key});

  @override
  State<ManifestListView> createState() => _ManifestListViewState();
}

class _ManifestListViewState extends State<ManifestListView> {
  late final OutboundManifestController controller;
  late final OutboundBranchListController branchList;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundManifestController>();
    branchList = Get.find<OutboundBranchListController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadManifestList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isManifestListLoading.value;
      final err = controller.manifestListError.value.trim();
      final rows = controller.manifestListPageRows;
      final page = controller.manifestListPage.value;
      final totalPages = controller.manifestListTotalPages;
      final rangeLabel = controller.manifestListRangeLabel;
      final filterNote = controller.selectedDepotSummary;
      final busy = controller.isBusy.value;
      final selectedDetail = controller.manifestDetail.value;
      final resultTitle = controller.manifestListResultTitle.value.trim();
      final responseText = controller.lastResponseText.value.trim();

      return OutboundScreen(
        title: OutboundLabels.manifestListTitle,
        busy: false,
        onRefresh: loading
            ? null
            : () async {
                await controller.loadManifestList();
              },
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnPerformManifest,
              onPressed: () => Get.back(),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.manifestListTitle,
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
                OutboundLabels.btnNewManifest,
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
                  onRetry: controller.loadManifestList,
                )
              else if (rows.isEmpty)
                const _ListMessage(
                    text: OutboundLabels.manifestListEmptyMessage)
              else ...[
                Text(
                  rangeLabel,
                  style:
                      themes.fontSize14_400.copyWith(color: themes.grayColor),
                ),
                _ManifestListTable(
                  rows: rows,
                  rowOffset: controller.manifestListRowNumberOffset,
                  branchLabel: branchList.displayLabelForId,
                  busy: busy,
                  onOpen: controller.applyManifestFromRow,
                  onDetails: controller.getManifestDetailsFromRow,
                  onPrint: controller.printManifestDataFromRow,
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
                          page > 1 ? controller.manifestListPreviousPage : null,
                    ),
                    end: OutboundSecondaryButton(
                      label: 'Next',
                      onPressed: page < totalPages
                          ? controller.manifestListNextPage
                          : null,
                    ),
                  ),
                ],
              ],
            ],
          ),
          if (selectedDetail != null)
            OutboundAdminSection(
              title: resultTitle.isEmpty
                  ? OutboundLabels.btnViewDetails
                  : resultTitle,
              children: [
                OutboundManifestDetailBody(
                  detail: selectedDetail,
                  compact: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutboundSecondaryButton(
                    label: OutboundLabels.btnFullManifestDetail,
                    onPressed: busy ? null : controller.openManifestDetailPage,
                  ),
                ),
              ],
            ),
          if (responseText.isNotEmpty)
            OutboundResponsePanel(
              title: resultTitle.isEmpty ? 'Message' : resultTitle,
              text: responseText,
            ),
        ],
      );
    });
  }
}

class _ManifestListTable extends StatelessWidget {
  const _ManifestListTable({
    required this.rows,
    required this.rowOffset,
    required this.branchLabel,
    required this.busy,
    required this.onOpen,
    required this.onDetails,
    required this.onPrint,
  });

  final List<OutboundManifestRow> rows;
  final int rowOffset;
  final String Function(String? id) branchLabel;
  final bool busy;
  final void Function(OutboundManifestRow row) onOpen;
  final void Function(OutboundManifestRow row) onDetails;
  final void Function(OutboundManifestRow row) onPrint;

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
            DataColumn(label: Text(OutboundLabels.manifestCode)),
            DataColumn(label: Text(OutboundLabels.colOrigin)),
            DataColumn(label: Text(OutboundLabels.colDestination)),
            DataColumn(label: Text(OutboundLabels.created)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(
                cells: [
                  DataCell(Text('${rowOffset + i + 1}')),
                  DataCell(
                    Text(
                      rows[i].manifestNo ?? rows[i].id ?? '—',
                      style: themes.fontSize14_500.copyWith(
                        color: themes.darkCyanBlue,
                      ),
                    ),
                  ),
                  DataCell(Text(branchLabel(rows[i].originBranch))),
                  DataCell(Text(branchLabel(rows[i].destinationBranch))),
                  DataCell(Text(rows[i].createdAt ?? '—')),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: busy ? null : () => onOpen(rows[i]),
                          child: const Text('Open'),
                        ),
                        TextButton(
                          onPressed: busy ? null : () => onDetails(rows[i]),
                          child: Text(OutboundLabels.btnViewDetails),
                        ),
                        TextButton(
                          onPressed: busy ? null : () => onPrint(rows[i]),
                          child: Text(OutboundLabels.btnPrint),
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
