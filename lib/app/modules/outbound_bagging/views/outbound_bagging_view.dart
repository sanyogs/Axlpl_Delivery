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
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// Admin **Bagging Screen** — origin/destination depot, M/Bag No, scan shipment, table, Save/Confirm.
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
      final statusMsg = controller.fetchStatusMessage.value.trim();
      final bagDetail = controller.bagDetail.value;
      final currentBagCode = controller.visibleBagCode;
      final _ = controller.scannedBoxRows.length;
      final __ = controller.selectedOriginDepotId.value;
      final ___ = controller.selectedDestDepotId.value;

      return OutboundScreen(
        title: OutboundLabels.baggingScreenTitle,
        busy: busy,
        children: [
          OutboundButtonRow(
            start: OutboundSecondaryButton(
              label: OutboundLabels.btnViewReport,
              onPressed: busy
                  ? null
                  : () => Get.toNamed(Routes.OUTBOUND_BAGGING_REPORT),
            ),
            end: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnShowList,
              onPressed:
                  busy ? null : () => Get.toNamed(Routes.OUTBOUND_BAG_LIST),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionBaggingDetails,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.originDepotCode,
                required: true,
                child: Obx(
                  () => OutboundBranchSelect(
                    label: OutboundLabels.originDepot,
                    dropdownHint: OutboundLabels.hintSelectOption,
                    showLabel: false,
                    compact: true,
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
                    dropdownHint: OutboundLabels.hintSelectOption,
                    showLabel: false,
                    compact: true,
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
                  hintText: OutboundLabels.hintMetalSealInput,
                  prefixIcon: const Icon(CupertinoIcons.tag),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.workingBagCode,
                child: Row(
                  children: [
                    Expanded(
                      child: OutboundScanField(
                        controller: controller.bagCodeWorkingController,
                        focusNode: controller.bagCodeFocusNode,
                        hintText: OutboundLabels.workingBagCode,
                        prefixIcon: const Icon(CupertinoIcons.cube_box),
                        onSubmitted: (_) => controller.loadBagByCode(),
                        onScanned: controller.onBagCodeScanned,
                      ),
                    ),
                    IconButton(
                      tooltip: OutboundLabels.btnCopy,
                      onPressed: currentBagCode.isEmpty
                          ? null
                          : () => _copyBagCode(currentBagCode),
                      icon: Icon(
                        Icons.copy_outlined,
                        color: currentBagCode.isEmpty
                            ? themes.grayColor
                            : themes.darkCyanBlue,
                      ),
                    ),
                  ],
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.scanShipmentId,
                child: OutboundScanField(
                  controller: controller.shipmentController,
                  focusNode: controller.shipmentFocusNode,
                  hintText: OutboundLabels.hintScanShipmentInput,
                  prefixIcon: const Icon(CupertinoIcons.barcode),
                  onSubmitted: (_) => controller.fetchShipment(),
                  onScanned: controller.onShipmentScanned,
                ),
              ),
              if (statusMsg.isNotEmpty)
                Text(
                  statusMsg,
                  style: themes.fontSize14_400.copyWith(color: themes.redColor),
                ),
              if (bagDetail != null)
                BaggingBagSummaryBanner(
                  detail: bagDetail,
                  onCopy: currentBagCode.isEmpty
                      ? null
                      : () => _copyBagCode(currentBagCode),
                ),
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
          KeyedSubtree(
            key: _scannedTableKey,
            child: OutboundAdminSection(
              title: OutboundLabels.sectionScannedBoxes,
              children: [
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

  Future<void> _copyBagCode(String code) async {
    final value = code.trim();
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    Get.snackbar('Bagging', 'Bag code copied.');
  }
}
