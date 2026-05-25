import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_item_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dynamic_map_table.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_branch_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_response_panel.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/views/outbound_hub_scan_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundBaggingView extends GetView<OutboundBaggingController> {
  const OutboundBaggingView({super.key});

  @override
  Widget build(BuildContext context) {
    final branchList = Get.find<OutboundBranchListController>();
    return Obx(() {
      final busy = controller.isBusy.value;
      final _ = controller.lastResponseText.value;
      final __ = controller.bagRows.length;
      final ___ = branchList.branches.length;
      final ____ = controller.selectedOriginDepotId.value;
      final _____ = controller.selectedDestDepotId.value;
      final ______ = controller.bagDetail.value;
      final _______ = controller.baggingReportData.value;
      return OutboundScreen(
        title: 'Bagging',
        busy: busy,
        children: [
          OutboundSection(
            title: 'Create bag',
            subtitle: OutboundLabels.subtitleCreateBag,
            children: [
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
              OutboundScanField(
                controller: controller.bagCodeController,
                hintText: OutboundLabels.metalSeal,
              ),
              OutboundScanField(
                controller: controller.createBagShipmentsController,
                hintText: OutboundLabels.shipmentIdsForCreateBag,
              ),
              OutboundSecondaryButton(
                label: OutboundLabels.useScanDocketForBag,
                onPressed: busy ? null : controller.useDocketForCreateBag,
              ),
              OutboundPrimaryButton(
                title: 'Create bag',
                onPressed: busy ? null : controller.createBag,
              ),
            ],
          ),
          OutboundSection(
            title: 'Scan shipments into bag',
            children: [
              OutboundScanField(
                controller: controller.bagCodeWorkingController,
                hintText: OutboundLabels.workingBagCode,
              ),
              OutboundScanField(
                controller: controller.docketController,
                hintText: OutboundLabels.shipmentNo,
              ),
              OutboundScanField(
                controller: controller.removeDocketController,
                hintText: OutboundLabels.removeRebagDocket,
              ),
              OutboundPrimaryButton(
                title: 'Add to bag',
                onPressed: busy ? null : controller.addShipment,
              ),
              OutboundButtonRow(
                start: OutboundSecondaryButton(
                  label: OutboundLabels.btnRemoveShipment,
                  onPressed: busy ? null : controller.removeShipment,
                ),
                end: OutboundSecondaryButton(
                  label: OutboundLabels.btnBagDetails,
                  onPressed: busy ? null : controller.getBagDetails,
                ),
              ),
              OutboundSecondaryButton(
                label: OutboundLabels.btnFullBagDetail,
                onPressed: busy ? null : controller.openBagDetailPage,
              ),
              if (controller.bagDetail.value != null)
                OutboundBagDetailBody(detail: controller.bagDetail.value!),
              OutboundPrimaryButton(
                title: 'Lock bag',
                onPressed: busy ? null : controller.lockBag,
              ),
              OutboundScanField(
                controller: controller.newBagCodeController,
                hintText: OutboundLabels.newBagCode,
              ),
              OutboundSecondaryButton(
                label: OutboundLabels.btnRebag,
                onPressed: busy ? null : controller.rebag,
              ),
            ],
          ),
          OutboundSection(
            title: 'Bag list',
            children: [
              OutboundPrimaryButton(
                title: OutboundLabels.btnListBags,
                onPressed: busy ? null : controller.listBags,
              ),
              OutboundDynamicMapTable(
                title: OutboundLabels.btnTapRowBag,
                rows: controller.listRows,
                onRowTap: busy ? null : controller.applyBagIdFromListRow,
              ),
            ],
          ),
          OutboundSection(
            title: 'Bagging report',
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
                title: OutboundLabels.btnBaggingReport,
                onPressed: busy ? null : controller.baggingReport,
              ),
              _BaggingReportItemsTable(
                items: controller.baggingReportData.value?.items ?? [],
              ),
            ],
          ),
          OutboundResponsePanel(text: controller.lastResponseText.value),
        ],
      );
    });
  }
}

class _BaggingReportItemsTable extends StatelessWidget {
  const _BaggingReportItemsTable({required this.items});
  final List<BaggingReportItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Shipment')),
          DataColumn(label: Text('Receiver')),
          DataColumn(label: Text('City')),
          DataColumn(label: Text('Weight')),
          DataColumn(label: Text('Pkgs')),
        ],
        rows: items
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text(e.shipmentId ?? '—')),
                  DataCell(Text(e.receiverName ?? e.senderName ?? '—')),
                  DataCell(Text(e.destinationCity ?? '—')),
                  DataCell(Text(e.totalWeight ?? '—')),
                  DataCell(Text(e.noOfPackage ?? '—')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
