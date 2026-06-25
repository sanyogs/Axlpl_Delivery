import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_status_report_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_copyable.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_select_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/sector_pickup_status_report_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin **Sector Pickup Status Report** — paginated `pickupreport` list.
class SectorPickupStatusReportView
    extends GetView<SectorPickupStatusReportController> {
  const SectorPickupStatusReportView({super.key});

  @override
  Widget build(BuildContext context) {
    final branchList = Get.find<OutboundBranchListController>();

    return Obx(() {
      final loading = controller.isLoading.value;
      final exporting = controller.isExporting.value;
      final busy = loading || exporting;
      final err = controller.loadError.value.trim();
      final rows = controller.rows;
      final page = controller.currentPage.value;
      final totalPages = controller.totalPages;
      final branchOptions = [
        SectorPickupStatusReportController.allBranchesLabel,
        ...branchList.branches.map((b) => b.label),
      ];
      String branchLabel(String? id) {
        if (id == null || id.trim().isEmpty) {
          return SectorPickupStatusReportController.allBranchesLabel;
        }
        return branchList.displayLabelForId(id);
      }

      void onOriginBranchChanged(String label) {
        if (label == SectorPickupStatusReportController.allBranchesLabel) {
          controller.filterOriginBranchId.value = null;
          return;
        }
        final opt = branchList.branches.firstWhereOrNull(
          (b) => b.label == label,
        );
        controller.filterOriginBranchId.value = opt?.id;
      }

      void onDestBranchChanged(String label) {
        if (label == SectorPickupStatusReportController.allBranchesLabel) {
          controller.filterDestBranchId.value = null;
          return;
        }
        final opt = branchList.branches.firstWhereOrNull(
          (b) => b.label == label,
        );
        controller.filterDestBranchId.value = opt?.id;
      }

      return OutboundScreen(
        title: OutboundLabels.sectorPickupStatusReportTitle,
        busy: busy,
        onRefresh: loading ? null : () => controller.loadReport(),
        children: [
          OutboundAdminSection(
            title: OutboundLabels.sectionReportFilters,
            children: [
              OutboundDateField(
                controller: controller.startDateController,
                hintText: '${OutboundLabels.reportStart} (optional)',
              ),
              OutboundDateField(
                controller: controller.endDateController,
                hintText: '${OutboundLabels.reportEnd} (optional)',
              ),
              OutboundSelectField(
                label: OutboundLabels.colOriginHub,
                value: branchLabel(controller.filterOriginBranchId.value),
                hint: SectorPickupStatusReportController.allBranchesLabel,
                options: branchOptions,
                onChanged: onOriginBranchChanged,
              ),
              OutboundSelectField(
                label: OutboundLabels.colDestinationHub,
                value: branchLabel(controller.filterDestBranchId.value),
                hint: SectorPickupStatusReportController.allBranchesLabel,
                options: branchOptions,
                onChanged: onDestBranchChanged,
              ),
              OutboundField(
                controller: controller.docketController,
                hintText: OutboundLabels.hintDocketAwb,
                prefixIcon: const Icon(Icons.search),
              ),
              OutboundSelectField(
                label: OutboundLabels.colStatus,
                value: controller.filterStatus.value ??
                    SectorPickupStatusReportController.allStatusLabel,
                hint: SectorPickupStatusReportController.allStatusLabel,
                options: SectorPickupStatusReportController.statusFilterOptions,
                onChanged: (v) => controller.filterStatus.value = v,
              ),
              OutboundField(
                controller: controller.linehaulController,
                hintText: OutboundLabels.hintLinehaulNo,
                prefixIcon: const Icon(Icons.local_shipping_outlined),
              ),
              OutboundButtonRow(
                start: OutboundSecondaryButton(
                  label: OutboundLabels.btnFilter,
                  onPressed: busy ? null : () => controller.loadReport(page: 1),
                ),
                end: OutboundSecondaryButton(
                  label: OutboundLabels.btnReset,
                  onPressed: busy ? null : controller.resetFilters,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OutboundPrimaryButtonCompact(
                  title: OutboundLabels.btnExportCsv,
                  onPressed: busy ? null : controller.exportCsv,
                  isLoading: exporting,
                ),
              ),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectorPickupStatusReportTitle,
            children: [
              if (loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: themes.darkCyanBlue),
                  ),
                )
              else if (err.isNotEmpty)
                Column(
                  children: [
                    Text(
                      err,
                      style: themes.fontSize14_400.copyWith(color: themes.redColor),
                    ),
                    SizedBox(height: 8.h),
                    OutboundSecondaryButton(
                      label: 'Retry',
                      onPressed: () => controller.loadReport(),
                    ),
                  ],
                )
              else if (rows.isEmpty)
                Text(
                  controller.totalCount > 0
                      ? 'Summary counts loaded. Clear filters or adjust dates, then tap Filter to load shipment rows.'
                      : OutboundLabels.sectorPickupStatusReportEmpty,
                  style:
                      themes.fontSize14_400.copyWith(color: themes.grayColor),
                )
              else ...[
                if (controller.rangeLabel.isNotEmpty)
                  Text(
                    controller.rangeLabel,
                    style:
                        themes.fontSize14_400.copyWith(color: themes.grayColor),
                  ),
                _StatusReportTable(rows: rows),
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
                          page > 1 && !busy ? controller.previousPage : null,
                    ),
                    end: OutboundSecondaryButton(
                      label: 'Next',
                      onPressed: page < totalPages && !busy
                          ? controller.nextPage
                          : null,
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

class _StatusReportTable extends StatelessWidget {
  const _StatusReportTable({required this.rows});

  final List<SectorPickupStatusReportRow> rows;

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
        child: DataTable(
          headingRowHeight: 40,
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 10.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text(OutboundLabels.colShipmentNo)),
            DataColumn(label: Text(OutboundLabels.colOriginHub)),
            DataColumn(label: Text(OutboundLabels.colDestinationHub)),
            DataColumn(label: Text(OutboundLabels.colLinehaulNo)),
            DataColumn(label: Text(OutboundLabels.colLinehaulDate)),
            DataColumn(label: Text(OutboundLabels.colPickupStatus)),
            DataColumn(label: Text(OutboundLabels.pickupDate)),
            DataColumn(label: Text(OutboundLabels.colCurrentStatus)),
          ],
          rows: rows
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(
                      OutboundCopyableTableCell(
                        value: e.displayShipmentNo,
                        emphasized: true,
                        snackbarTitle: 'Sector pickup',
                      ),
                    ),
                    DataCell(Text(_cell(e.origin))),
                    DataCell(Text(_cell(e.destination))),
                    DataCell(
                      OutboundCopyableTableCell(
                        value: e.linehaulNo,
                        snackbarTitle: 'Sector pickup',
                      ),
                    ),
                    DataCell(Text(_cell(e.linehaulDate))),
                    DataCell(Text(e.pickupStatusShort)),
                    DataCell(Text(_cell(e.pickupDate))),
                    DataCell(Text(_cell(e.currentStatus))),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  static String _cell(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return '—';
    return t;
  }
}
