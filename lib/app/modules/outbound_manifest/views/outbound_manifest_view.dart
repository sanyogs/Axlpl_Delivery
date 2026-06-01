import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_manifest_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_branch_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_expandable_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_response_panel.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/views/outbound_hub_scan_view.dart';
import 'package:axlpl_delivery/app/modules/outbound_manifest/controllers/outbound_manifest_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OutboundManifestView extends GetView<OutboundManifestController> {
  const OutboundManifestView({super.key});

  @override
  Widget build(BuildContext context) {
    final branchList = Get.find<OutboundBranchListController>();
    return Obx(() {
      final busy = controller.isBusy.value;
      final _ = controller.lastResponseText.value;
      final __ = controller.manifestRows.length;
      final ___ = controller.manifestDetail.value;
      final ____ = controller.manifestReportData.value;
      final ______ = branchList.branches.length;
      return OutboundScreen(
        title: 'Manifest',
        busy: busy,
        children: [
          OutboundExpandableSection(
            title: 'Create manifest',
            subtitle: OutboundLabels.subtitleManifestCreate,
            initiallyExpanded: true,
            children: [
              OutboundScanField(
                controller: controller.bagCodesController,
                hintText: OutboundLabels.bagCodesCsv,
              ),
              Obx(
                () => OutboundBranchSelect(
                  label: OutboundLabels.originDepot,
                  items: branchList.branches,
                  selectedId: controller.selectedOriginDepotId.value,
                  isLoading: branchList.isLoadingBranches.value,
                  onChanged: (id) => controller.selectedOriginDepotId.value = id,
                ),
              ),
              Obx(
                () => OutboundBranchSelect(
                  label: OutboundLabels.destinationDepot,
                  items: branchList.branches,
                  selectedId: controller.selectedDestDepotId.value,
                  isLoading: branchList.isLoadingBranches.value,
                  onChanged: (id) => controller.selectedDestDepotId.value = id,
                ),
              ),
              OutboundPrimaryButton(
                title: 'Create manifest',
                onPressed: busy ? null : controller.createManifest,
              ),
            ],
          ),
          OutboundExpandableSection(
            title: 'Open manifest',
            subtitle: OutboundLabels.subtitleManifestOpen,
            initiallyExpanded: true,
            children: [
              Obx(
                () => OutboundBranchSelect(
                  label: OutboundLabels.listDepot,
                  items: branchList.branches,
                  selectedId: controller.selectedListDepotId.value,
                  isLoading: branchList.isLoadingBranches.value,
                  onChanged: (id) => controller.selectedListDepotId.value = id,
                ),
              ),
              OutboundPrimaryButton(
                title: 'List manifests',
                onPressed: busy ? null : controller.listManifests,
              ),
              OutboundBoundedTableBox(
                maxHeight: 200,
                child: SingleChildScrollView(
                  child: _ManifestListTable(
                    rows: controller.manifestRows,
                    branchLabel: branchList.displayLabelForId,
                    onRowTap: busy ? null : controller.applyManifestFromRow,
                  ),
                ),
              ),
              OutboundScanField(
                controller: controller.manifestCodeController,
                hintText: OutboundLabels.manifestCode,
              ),
              OutboundButtonRow(
                start: OutboundSecondaryButton(
                  label: OutboundLabels.btnViewDetails,
                  onPressed: busy ? null : controller.getManifestDetails,
                ),
                end: OutboundSecondaryButton(
                  label: OutboundLabels.btnPrint,
                  onPressed: busy ? null : controller.printManifestData,
                ),
              ),
              if (controller.manifestDetail.value != null)
                OutboundManifestDetailBody(
                  detail: controller.manifestDetail.value!,
                  compact: true,
                ),
              OutboundSecondaryButton(
                label: OutboundLabels.btnFullManifestDetail,
                onPressed: busy ? null : controller.openManifestDetailPage,
              ),
            ],
          ),
          OutboundExpandableSection(
            title: 'Manifest report',
            subtitle: OutboundLabels.subtitleManifestReport,
            initiallyExpanded: false,
            children: [
              OutboundDateField(
                controller: controller.reportStartController,
                hintText: OutboundLabels.reportStart,
              ),
              OutboundDateField(
                controller: controller.reportEndController,
                hintText: OutboundLabels.reportEnd,
              ),
              OutboundPrimaryButton(
                title: 'Generate report',
                onPressed: busy ? null : controller.manifestReport,
              ),
              if (controller.manifestReportData.value != null &&
                  (controller.manifestReportData.value!.bags.isNotEmpty ||
                      controller.manifestReportData.value!.shipments.isNotEmpty)) ...[
                OutboundBoundedTableBox(
                  maxHeight: 160,
                  child: SingleChildScrollView(
                    child: _ManifestReportBagsTable(
                      bags: controller.manifestReportData.value!.bags,
                    ),
                  ),
                ),
                OutboundBoundedTableBox(
                  maxHeight: 160,
                  child: SingleChildScrollView(
                    child: _ManifestReportShipmentsTable(
                      shipments:
                          controller.manifestReportData.value!.shipments,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (controller.lastResponseText.value.trim().isNotEmpty)
            OutboundResponsePanel(
              title: 'Message',
              text: controller.lastResponseText.value,
            ),
        ],
      );
    });
  }
}

class _ManifestListTable extends StatelessWidget {
  const _ManifestListTable({
    required this.rows,
    required this.branchLabel,
    this.onRowTap,
  });

  final List<OutboundManifestRow> rows;
  final String Function(String? id) branchLabel;
  final void Function(OutboundManifestRow row)? onRowTap;

  String _branch(String? id) {
    if (id == null || id.trim().isEmpty) return '—';
    return branchLabel(id);
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 40,
          headingTextStyle: themes.fontSize14_500,
          columns: const [
            DataColumn(label: Text('Manifest')),
            DataColumn(label: Text('Origin')),
            DataColumn(label: Text('Destination')),
            DataColumn(label: Text('Created')),
          ],
          rows: rows
              .map(
                (e) => DataRow(
                  onSelectChanged: onRowTap == null
                      ? null
                      : (_) => onRowTap!(e),
                  cells: [
                    DataCell(Text(e.manifestNo ?? e.id ?? '—')),
                    DataCell(Text(_branch(e.originBranch))),
                    DataCell(Text(_branch(e.destinationBranch))),
                    DataCell(Text(e.createdAt ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ManifestReportBagsTable extends StatelessWidget {
  const _ManifestReportBagsTable({required this.bags});
  final List<ManifestBagRef> bags;

  @override
  Widget build(BuildContext context) {
    if (bags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 40,
          headingTextStyle: themes.fontSize14_500,
          columns: const [
            DataColumn(label: Text('Bag code')),
            DataColumn(label: Text('Metal seal')),
            DataColumn(label: Text('Weight')),
          ],
          rows: bags
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(Text(e.bagCode ?? '—')),
                    DataCell(Text(e.metalSealNo ?? '—')),
                    DataCell(Text(e.grossWeight ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ManifestReportShipmentsTable extends StatelessWidget {
  const _ManifestReportShipmentsTable({required this.shipments});
  final List<ManifestShipmentRef> shipments;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 40,
          headingTextStyle: themes.fontSize14_500,
          columns: const [
            DataColumn(label: Text('Shipment')),
            DataColumn(label: Text('Receiver')),
            DataColumn(label: Text('City')),
            DataColumn(label: Text('Gross wt')),
            DataColumn(label: Text('Vol wt')),
          ],
          rows: shipments
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(Text(e.id ?? '—')),
                    DataCell(Text(e.receiverName ?? e.senderName ?? '—')),
                    DataCell(Text(e.destinationCity ?? '—')),
                    DataCell(Text(e.grossWeight ?? '—')),
                    DataCell(Text(e.volumetricWeight ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
