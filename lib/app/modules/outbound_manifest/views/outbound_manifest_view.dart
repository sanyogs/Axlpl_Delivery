import 'package:axlpl_delivery/app/data/models/outbound/manifest_session_models.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_branch_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_transport_mode_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_manifest/controllers/outbound_manifest_controller.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin **Manifest Screen** — origin/destination, scan M/Bags, summary, create.
class OutboundManifestView extends StatefulWidget {
  const OutboundManifestView({super.key});

  @override
  State<OutboundManifestView> createState() => _OutboundManifestViewState();
}

class _OutboundManifestViewState extends State<OutboundManifestView> {
  final _bagTableKey = GlobalKey();
  late final OutboundManifestController controller;
  Worker? _scrollWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundManifestController>();
    _scrollWorker = ever(controller.sessionBags, (_) {
      if (controller.sessionBags.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _bagTableKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            alignment: 0.12,
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
      final _ = controller.sessionBags.length;
      final __ = controller.shipmentLines.length;
      final ___ = controller.selectedOriginDepotId.value;
      final ____ = controller.selectedDestDepotId.value;
      final _____ = controller.selectedTransportMode.value;

      return OutboundScreen(
        title: OutboundLabels.manifestScreenTitle,
        busy: busy,
        children: [
          OutboundButtonRow(
            start: OutboundSecondaryButton(
              label: OutboundLabels.btnViewReport,
              onPressed: busy
                  ? null
                  : () => Get.toNamed(Routes.OUTBOUND_MANIFEST_REPORT),
            ),
            end: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnShowList,
              onPressed:
                  busy ? null : () => Get.toNamed(Routes.OUTBOUND_MANIFEST_LIST),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionManifestDetails,
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
                label: OutboundLabels.colMode,
                child: Obx(
                  () => OutboundTransportModeField(
                    value: controller.selectedTransportMode.value,
                    onChanged: controller.onTransportModeChanged,
                  ),
                ),
              ),
              const _ManifestSummaryGrid(),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionMBagDetails,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.mBagCode,
                required: true,
                child: OutboundScanField(
                  controller: controller.bagScanController,
                  focusNode: controller.bagScanFocusNode,
                  hintText: OutboundLabels.hintScanMBagCode,
                  prefixIcon: const Icon(CupertinoIcons.cube_box),
                  onSubmitted: (_) => controller.onBagScanFocusLost(),
                  onScanned: controller.onBagScanned,
                ),
              ),
              if (statusMsg.isNotEmpty)
                Text(
                  statusMsg,
                  style: themes.fontSize14_400.copyWith(color: themes.redColor),
                ),
              _ManifestBagTable(
                key: _bagTableKey,
                rows: controller.sessionBags,
                onRemove: busy ? null : controller.removeSessionBag,
              ),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionManifestShipmentDetails,
            children: [
              _ManifestShipmentTable(rows: controller.shipmentLines),
            ],
          ),
          OutboundPrimaryButton(
            title: OutboundLabels.btnAddManifest,
            onPressed: busy ? null : controller.createManifest,
          ),
        ],
      );
    });
  }
}

/// Admin video: 3×2 summary grid (counts top row, weights bottom row).
class _ManifestSummaryGrid extends GetView<OutboundManifestController> {
  const _ManifestSummaryGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Expanded(
              child: OutboundLabeledFieldRow(
                label: OutboundLabels.connoteCount,
                child: OutboundReadOnlyInput(
                  controller: controller.connoteCountController,
                ),
              ),
            ),
            Expanded(
              child: OutboundLabeledFieldRow(
                label: OutboundLabels.boxCount,
                child: OutboundReadOnlyInput(
                  controller: controller.boxCountController,
                ),
              ),
            ),
            Expanded(
              child: OutboundLabeledFieldRow(
                label: OutboundLabels.bagsSelectedCount,
                child: OutboundReadOnlyInput(
                  controller: controller.bagsSelectedController,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Expanded(
              child: OutboundLabeledFieldRow(
                label: OutboundLabels.connoteWeight,
                child: OutboundReadOnlyInput(
                  controller: controller.connoteWeightController,
                ),
              ),
            ),
            Expanded(
              child: OutboundLabeledFieldRow(
                label: OutboundLabels.conVolWeight,
                child: OutboundReadOnlyInput(
                  controller: controller.conVolWeightController,
                ),
              ),
            ),
            Expanded(
              child: OutboundLabeledFieldRow(
                label: OutboundLabels.bagWeight,
                child: OutboundReadOnlyInput(
                  controller: controller.bagWeightController,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManifestBagTable extends StatelessWidget {
  const _ManifestBagTable({
    super.key,
    required this.rows,
    this.onRemove,
  });

  final List<ManifestBagSessionRow> rows;
  final void Function(ManifestBagSessionRow row)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        OutboundLabels.manifestBagTableEmpty,
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
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
            DataColumn(label: Text(OutboundLabels.colMBagNumber)),
            DataColumn(label: Text(OutboundLabels.colOrigin)),
            DataColumn(label: Text(OutboundLabels.colDestination)),
            DataColumn(label: Text(OutboundLabels.colWeight)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  DataCell(
                    Text(
                      row.bagCode,
                      style: themes.fontSize14_500.copyWith(
                        color: themes.darkCyanBlue,
                      ),
                    ),
                  ),
                  DataCell(Text(row.originLabel)),
                  DataCell(Text(row.destinationLabel)),
                  DataCell(Text(row.weight ?? '—')),
                  DataCell(
                    onRemove == null
                        ? const SizedBox.shrink()
                        : TextButton(
                            onPressed: () => onRemove!(row),
                            child: Text(OutboundLabels.btnRemoveShipment),
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

class _ManifestShipmentTable extends StatelessWidget {
  const _ManifestShipmentTable({required this.rows});

  final List<ManifestShipmentSessionRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        OutboundLabels.manifestShipmentTableEmpty,
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
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
            fontSize: 10.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text(OutboundLabels.colMBagNumber)),
            DataColumn(label: Text(OutboundLabels.colBoxNo)),
            DataColumn(label: Text(OutboundLabels.colConsignmentNo)),
            DataColumn(label: Text(OutboundLabels.colOrigin)),
            DataColumn(label: Text(OutboundLabels.colConsigneeCode)),
            DataColumn(label: Text(OutboundLabels.colConsigneeName)),
            DataColumn(label: Text(OutboundLabels.colCityName)),
            DataColumn(label: Text(OutboundLabels.colPcs)),
            DataColumn(label: Text(OutboundLabels.colDescription)),
            DataColumn(label: Text(OutboundLabels.colInvVal)),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  DataCell(Text(row.bagNumber)),
                  DataCell(Text(row.boxNo ?? '—')),
                  DataCell(Text(row.consignmentNo ?? '—')),
                  DataCell(Text(row.origin ?? '—')),
                  DataCell(Text(row.consigneeCode ?? '—')),
                  DataCell(Text(row.consigneeName ?? '—')),
                  DataCell(Text(row.cityName ?? '—')),
                  DataCell(Text(row.pcs ?? '—')),
                  DataCell(Text(row.description ?? '—')),
                  DataCell(Text(row.invVal ?? '—')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
