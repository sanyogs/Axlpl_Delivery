import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/widgets/bagging_bag_summary.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/widgets/bagging_scanned_box_table.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_branch_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OutboundBaggingView extends StatefulWidget {
  const OutboundBaggingView({super.key});

  @override
  State<OutboundBaggingView> createState() => _OutboundBaggingViewState();
}

class _OutboundBaggingViewState extends State<OutboundBaggingView> {
  final _scannedTableKey = GlobalKey();
  late final OutboundBaggingController controller;
  Worker? _scrollWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundBaggingController>();
    _scrollWorker = ever(controller.scrollToScannedTable, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _scannedTableKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            alignment: 0.15,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final branchList = Get.find<OutboundBranchListController>();
    return Obx(() {
      final busy = controller.isBusy.value;
      final detail = controller.bagDetail.value;
      final statusMsg = controller.fetchStatusMessage.value.trim();
      final _ = controller.sessionScannedRows.length;
      final __ = controller.scannedBoxRows.length;
      final ___ = controller.selectedOriginDepotId.value;
      final ____ = controller.selectedDestDepotId.value;

      return OutboundScreen(
        title: OutboundLabels.baggingScreenTitle,
        busy: busy,
        children: [
          OutboundButtonRow(
            start: OutboundSecondaryButton(
              label: OutboundLabels.btnViewReport,
              onPressed: busy ? null : () => Get.toNamed(Routes.OUTBOUND_BAGGING_REPORT),
            ),
            end: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnShowList,
              onPressed: busy ? null : () => Get.toNamed(Routes.OUTBOUND_BAG_LIST),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionBaggingDetails,
            children: [
              Text(
                OutboundLabels.subtitleCreateBag,
                style: themes.fontSize14_400.copyWith(color: themes.grayColor),
              ),
              if (controller.selectedDepotSummary.isNotEmpty)
                Text(
                  controller.selectedDepotSummary,
                  style: themes.fontSize14_500,
                ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.originDepotCode,
                required: true,
                child: Obx(
                  () => OutboundBranchSelect(
                    label: OutboundLabels.originDepot,
                    items: branchList.branches,
                    selectedId: controller.selectedOriginDepotId.value,
                    isLoading: branchList.isLoadingBranches.value,
                    onChanged: controller.onOriginDepotChanged,
                  ),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.destinationDepotCode,
                required: true,
                child: Obx(
                  () => OutboundBranchSelect(
                    label: OutboundLabels.destinationDepot,
                    items: branchList.branches,
                    selectedId: controller.selectedDestDepotId.value,
                    isLoading: branchList.isLoadingBranches.value,
                    onChanged: controller.onDestinationDepotChanged,
                  ),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.mBagNo,
                required: true,
                child: OutboundScanField(
                  controller: controller.metalSealController,
                  hintText: OutboundLabels.metalSeal,
                  prefixIcon: const Icon(CupertinoIcons.tag),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.bagCode,
                child: Obx(
                  () => IgnorePointer(
                    ignoring: controller.isBagCodeFromServer,
                    child: OutboundScanField(
                      controller: controller.bagCodeWorkingController,
                      focusNode: controller.bagCodeFocusNode,
                      hintText: OutboundLabels.bagCode,
                      prefixIcon: const Icon(CupertinoIcons.cube_box),
                      onSubmitted: (_) => controller.loadBagByCode(),
                      onScanned: controller.onBagCodeScanned,
                    ),
                  ),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.scanShipmentId,
                required: true,
                child: OutboundScanField(
                  controller: controller.shipmentController,
                  focusNode: controller.shipmentFocusNode,
                  hintText: OutboundLabels.docketNo,
                  prefixIcon: const Icon(CupertinoIcons.barcode),
                  onSubmitted: (_) => controller.fetchShipment(),
                  onScanned: controller.onShipmentScanned,
                ),
              ),
              if (statusMsg.isNotEmpty)
                Text(
                  statusMsg,
                  style: themes.fontSize14_400.copyWith(color: themes.grayColor),
                ),
              if (detail != null) ...[
                SizedBox(height: 4.h),
                BaggingBagSummaryBanner(detail: detail),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 260.w,
                  child: OutboundButtonRow(
                    start: OutboundSecondaryButton(
                      label: OutboundLabels.btnSave,
                      onPressed: busy ? null : controller.saveBagging,
                    ),
                    end: OutboundPrimaryButtonCompact(
                      title: OutboundLabels.btnConfirm,
                      onPressed: busy ? null : controller.confirmBagging,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (detail != null)
            OutboundAdminSection(
              title: 'Current bag',
              children: [BaggingBagSummary(detail: detail)],
            ),
          KeyedSubtree(
            key: _scannedTableKey,
            child: OutboundAdminSection(
              title: OutboundLabels.sectionScannedBoxes,
              children: [
                Text(
                  '${OutboundLabels.shipmentCount}: ${controller.totalScannedBoxes}',
                  style: themes.fontSize14_500,
                ),
                BaggingScannedBoxTable(
                  rows: controller.scannedBoxRows,
                  onRemove: busy ? null : controller.removeScannedRow,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}
