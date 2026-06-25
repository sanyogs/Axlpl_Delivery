import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_expandable_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_copyable.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_select_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/outbound_linehaul_controller.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// `listlinehauls` — management table with details and create shortcut.
class LinehaulListView extends StatefulWidget {
  const LinehaulListView({super.key});

  @override
  State<LinehaulListView> createState() => _LinehaulListViewState();
}

class _LinehaulListViewState extends State<LinehaulListView> {
  late final OutboundLinehaulController controller;
  late final OutboundBranchListController branchList;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundLinehaulController>();
    branchList = Get.find<OutboundBranchListController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLinehaulList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLinehaulListLoading.value;
      final err = controller.linehaulListError.value.trim();
      final rows = controller.linehaulRows;
      final busy = controller.isBusy.value;
      final detail = controller.linehaulDetail.value;
      final selectedRef = controller.selectedListLinehaulRef.value;

      return OutboundScreen(
        title: OutboundLabels.linehaulListTitle,
        busy: busy,
        onRefresh: loading
            ? null
            : () async {
                await controller.loadLinehaulList();
              },
        children: [
          OutboundAdminSection(
            title: OutboundLabels.linehaulListTitle,
            trailing: TextButton.icon(
              onPressed: () => Get.toNamed(Routes.OUTBOUND_LINEHAUL),
              style: TextButton.styleFrom(
                backgroundColor: themes.whiteColor,
                foregroundColor: themes.darkCyanBlue,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.add, size: 16.sp, color: themes.darkCyanBlue),
              label: Text(
                OutboundLabels.btnCreateNewLinehaul,
                style: themes.fontSize14_500.copyWith(
                  fontSize: 11.sp,
                  color: themes.darkCyanBlue,
                ),
              ),
            ),
            children: [
              OutboundSelectField(
                label: OutboundLabels.linehaulFilterStatus,
                value: controller.listFilterStatus.value,
                hint: OutboundLabels.selectStatus,
                options: OutboundLinehaulController.listStatusOptions,
                onChanged: (v) => controller.listFilterStatus.value = v,
              ),
              OutboundSecondaryButton(
                label: OutboundLabels.btnRefreshList,
                onPressed: loading ? null : controller.loadLinehaulList,
              ),
              if (loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child: CircularProgressIndicator(color: themes.darkCyanBlue),
                  ),
                )
              else if (err.isNotEmpty)
                _ListMessage(text: err, onRetry: controller.loadLinehaulList)
              else if (rows.isEmpty)
                const _ListMessage(text: OutboundLabels.linehaulListEmptyMessage)
              else
                _LinehaulListTable(
                  rows: rows,
                  branchLabel: branchList.displayLabelForId,
                  onDetails: (row) => controller.openLinehaulDetailsFromList(row),
                  onEdit: (row) => controller.openLinehaulEdit(row),
                  onDelete: (row) => controller.confirmDeleteLinehaulFromList(row),
                ),
            ],
          ),
          if (selectedRef != null && selectedRef.isNotEmpty)
            OutboundExpandableSection(
              title: OutboundLabels.sectionLinehaulDetailStatus,
              subtitle: selectedRef,
              initiallyExpanded: false,
              children: [
                if (detail != null) OutboundLinehaulDetailBody(detail: detail),
                OutboundSecondaryButton(
                  label: OutboundLabels.btnFullLinehaulDetail,
                  onPressed: busy ? null : controller.openLinehaulDetailPage,
                ),
                OutboundSelectField(
                  label: OutboundLabels.newLinehaulStatus,
                  value: controller.updateStatus.value,
                  hint: OutboundLabels.selectStatus,
                  options: OutboundLinehaulController.updateStatusOptions,
                  onChanged: (v) => controller.updateStatus.value = v,
                ),
                OutboundPrimaryButton(
                  title: OutboundLabels.btnUpdateLinehaulStatus,
                  onPressed: busy ? null : controller.updateLinehaulStatus,
                ),
              ],
            ),
        ],
      );
    });
  }
}

class _LinehaulListTable extends StatelessWidget {
  const _LinehaulListTable({
    required this.rows,
    required this.branchLabel,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OutboundLinehaulRow> rows;
  final String Function(String? id) branchLabel;
  final void Function(OutboundLinehaulRow row) onDetails;
  final void Function(OutboundLinehaulRow row) onEdit;
  final void Function(OutboundLinehaulRow row) onDelete;

  String _hub(String? id, String? fallback) {
    if (id != null && id.trim().isNotEmpty) return branchLabel(id);
    final fb = fallback?.trim();
    if (fb != null && fb.isNotEmpty) return fb;
    return '—';
  }

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
            DataColumn(label: Text(OutboundLabels.colMawbVehicle)),
            DataColumn(label: Text(OutboundLabels.colOriginHub)),
            DataColumn(label: Text(OutboundLabels.colDestinationHub)),
            DataColumn(label: Text(OutboundLabels.colTransport)),
            DataColumn(label: Text(OutboundLabels.colBookingDate)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutboundCopyableTableCell(
                            value: row.mawbNo ?? row.vehicleNo ?? row.tripNo,
                            displayText: row.displayMawbOrVehicle,
                            emphasized: true,
                            snackbarTitle: 'Linehaul',
                          ),
                          if (row.ewayBill?.trim().isNotEmpty == true)
                            OutboundCopyableInline(
                              text: 'EWB: ${row.ewayBill!.trim()}',
                              value: row.ewayBill,
                              style: themes.fontSize14_400.copyWith(
                                fontSize: 10.sp,
                                color: themes.grayColor,
                              ),
                              snackbarTitle: 'Linehaul',
                              compact: true,
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text(_hub(row.origin, row.origin))),
                    DataCell(Text(_hub(row.destination, row.destination))),
                    DataCell(_TransportChip(label: row.transportType ?? row.driverName)),
                    DataCell(Text(row.bookingDate ?? '—')),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => onDetails(row),
                            child: Text(OutboundLabels.btnDetails),
                          ),
                          IconButton(
                            tooltip: OutboundLabels.btnEdit,
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18.sp,
                              color: themes.darkCyanBlue,
                            ),
                            onPressed: () => onEdit(row),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          IconButton(
                            tooltip: OutboundLabels.btnDelete,
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18.sp,
                              color: themes.redColor,
                            ),
                            onPressed: () => onDelete(row),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TransportChip extends StatelessWidget {
  const _TransportChip({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label?.trim();
    if (text == null || text.isEmpty) return const Text('—');
    final upper = text.toUpperCase();
    final isAir = upper.contains('AIR');
    final bg = isAir
        ? themes.darkCyanBlue.withValues(alpha: 0.12)
        : const Color(0xFFFFF3E0);
    final fg = isAir ? themes.darkCyanBlue : const Color(0xFFE65100);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        upper.length > 12 ? upper.substring(0, 12) : upper,
        style: themes.fontSize14_500.copyWith(fontSize: 10.sp, color: fg),
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
