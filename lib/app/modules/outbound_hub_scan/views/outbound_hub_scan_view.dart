import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_table_row.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_branch_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_select_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/controllers/outbound_hub_scan_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/widgets/hub_scan_session_card.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OutboundHubScanView extends StatefulWidget {
  const OutboundHubScanView({super.key});

  @override
  State<OutboundHubScanView> createState() => _OutboundHubScanViewState();
}

class _OutboundHubScanViewState extends State<OutboundHubScanView> {
  final _sessionTableKey = GlobalKey();
  late final OutboundHubScanController controller;
  Worker? _scrollWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundHubScanController>();
    _scrollWorker = ever(controller.scrollToSessionTable, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _sessionTableKey.currentContext;
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
      final _ = controller.fetchStatusMessage.value;
      final __ = controller.fetchedShipment.value;
      final ___ = controller.sessionScannedRows
          .map((r) => '${r.sessionKey}:${r.saved}:${r.docketNo}')
          .join('|');
      final ____ = branchList.branches.length;
      final _____ = branchList.selectedBranchId.value;
      return OutboundScreen(
        title: 'Docket Scan Screen',
        busy: busy,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnShowList,
              onPressed: busy ? null : _openHubScanList,
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionDocketDetails,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.scanDocketNo,
                required: true,
                child: OutboundScanField(
                  controller: controller.docketController,
                  focusNode: controller.docketFocusNode,
                  hintText: OutboundLabels.scanDocketNo,
                  prefixIcon: const Icon(CupertinoIcons.barcode),
                  onSubmitted: (_) => controller.fetchShipment(),
                  onScanned: controller.onConnoteScanned,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.scanType,
                required: true,
                child: _ScanTypeDropdown(
                  value: controller.status.value,
                  options: controller.statuses,
                  onChanged: (v) => controller.status.value = v,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.branchHub,
                required: true,
                child: Obx(
                  () => OutboundBranchSelect(
                    label: '',
                    items: branchList.branches,
                    selectedId: branchList.selectedBranchId.value,
                    isLoading: branchList.isLoadingBranches.value,
                    onChanged: (id) {
                      branchList.onBranchSelected(id);
                      branchList.showLoadIssueIfNeeded();
                    },
                  ),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.clientCode,
                child: OutboundReadOnlyInput(controller: controller.clientCodeController),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.noOfBox,
                child: OutboundReadOnlyInput(controller: controller.noOfBoxController),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.boxWeight,
                child: OutboundReadOnlyInput(controller: controller.boxWeightController),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.originPincode,
                child: OutboundReadOnlyInput(controller: controller.originPincodeController),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.destPincode,
                child: OutboundReadOnlyInput(controller: controller.destPincodeController),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.destCity,
                child: OutboundReadOnlyInput(controller: controller.destCityController),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 260.w,
                  child: OutboundButtonRow(
                    start: OutboundSecondaryButton(
                      label: OutboundLabels.btnSave,
                      onPressed: busy ? null : controller.saveHubScan,
                    ),
                    end: OutboundPrimaryButtonCompact(
                      title: OutboundLabels.btnConfirm,
                      onPressed: busy ? null : controller.confirmHubScan,
                    ),
                  ),
                ),
              ),
            ],
          ),
          KeyedSubtree(
            key: _sessionTableKey,
            child: OutboundAdminSection(
              title: OutboundLabels.sectionScannedDockets,
              children: [
                Row(
                  children: [
                    Text(
                      '${OutboundLabels.totalScanned}: ${controller.totalScanned}',
                      style: themes.fontSize14_500,
                    ),
                    SizedBox(width: 20.w),
                    Text(
                      '${OutboundLabels.totalParcels}: ${controller.totalParcels}',
                      style: themes.fontSize14_500,
                    ),
                  ],
                ),
                _ScannedDocketDetailsList(
                  rows: controller.sessionScannedRows.toList(growable: false),
                  branchLabel: branchList.displayLabelForId,
                  onRemove: controller.removeSessionRow,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _openHubScanList() {
    Get.toNamed(Routes.OUTBOUND_HUB_SCAN_LIST);
  }
}

class _ScanTypeDropdown extends StatelessWidget {
  const _ScanTypeDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutboundSelectField(
      label: '',
      value: value,
      hint: OutboundLabels.selectStatus,
      options: options,
      onChanged: onChanged,
    );
  }
}

class _ScannedDocketDetailsList extends StatelessWidget {
  const _ScannedDocketDetailsList({
    required this.rows,
    required this.branchLabel,
    required this.onRemove,
  });

  final List<HubScanTableRow> rows;
  final String Function(String? id) branchLabel;
  final void Function(String sessionKey) onRemove;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        for (final row in rows)
          HubScanSessionCard(
            row: row,
            branchLabel: branchLabel,
            onRemove: row.saved ? null : () => onRemove(row.sessionKey),
          ),
      ],
    );
  }
}

/// Empty-state line for nested outbound tables (imported by bag/manifest/linehaul).
class OutboundDynamicMapTablePlaceholder extends StatelessWidget {
  const OutboundDynamicMapTablePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'No rows loaded yet.',
      style: themes.fontSize14_400.copyWith(color: themes.grayColor),
    );
  }
}
