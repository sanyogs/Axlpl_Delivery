import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_session_models.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_time_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/outbound_sector_pickup_controller.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OutboundSectorPickupView extends StatefulWidget {
  const OutboundSectorPickupView({super.key});

  @override
  State<OutboundSectorPickupView> createState() =>
      _OutboundSectorPickupViewState();
}

class _OutboundSectorPickupViewState extends State<OutboundSectorPickupView> {
  final _scannedTableKey = GlobalKey();
  late final OutboundSectorPickupController controller;
  Worker? _scrollWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundSectorPickupController>();
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
    return Obx(() {
      final busy = controller.isBusy.value;
      final _ = controller.scannedRows.length;
      final __ = controller.missingRows.length;
      final ___ = controller.manifestedCount;

      return OutboundScreen(
        title: OutboundLabels.sectorPickupScreenTitle,
        busy: busy,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnBackToList,
              onPressed: busy ? null : _backToList,
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionTransactionHeader,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.mawbNumber,
                required: true,
                child: OutboundScanField(
                  controller: controller.mawbController,
                  hintText: OutboundLabels.mawbNumber,
                  prefixIcon: const Icon(CupertinoIcons.barcode),
                  onSubmitted: (_) => controller.onMawbSubmitted(),
                  onScanned: controller.onMawbScanned,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.originHub,
                child: OutboundReadOnlyInput(
                  controller: controller.originHubController,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.destHub,
                child: OutboundReadOnlyInput(
                  controller: controller.destHubController,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.pickupDate,
                child: OutboundDateField(
                  controller: controller.pickupDateController,
                  hintText: OutboundLabels.pickupDate,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.pickupTime,
                child: OutboundTimeField(
                  controller: controller.pickupTimeController,
                  hintText: OutboundLabels.pickupTime,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.pickedBy,
                child: OutboundAdminInput(
                  controller: controller.pickedByController,
                  hintText: OutboundLabels.pickedBy,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.flightInfo,
                child: OutboundReadOnlyInput(
                  controller: controller.flightInfoController,
                ),
              ),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionScanners,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.step1ScanBagSeal,
                child: OutboundScanField(
                  controller: controller.bagSealController,
                  focusNode: controller.bagSealFocusNode,
                  hintText: OutboundLabels.hintMetalSealInput,
                  prefixIcon: const Icon(CupertinoIcons.tag),
                  onSubmitted: (_) => controller.onBagSealSubmitted(),
                  onScanned: controller.onBagSealScanned,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.step2ScanDocket,
                required: true,
                child: OutboundScanField(
                  controller: controller.docketController,
                  focusNode: controller.docketFocusNode,
                  hintText: OutboundLabels.scanDocketNo,
                  prefixIcon: const Icon(CupertinoIcons.barcode),
                  onSubmitted: (_) => controller.onDocketSubmitted(),
                  onScanned: controller.onDocketScanned,
                ),
              ),
            ],
          ),
          _SummaryStatsRow(
            manifested: controller.manifestedCount,
            scanned: controller.scannedCount,
            missing: controller.missingCount,
          ),
          KeyedSubtree(
            key: _scannedTableKey,
            child: OutboundAdminSection(
              title: OutboundLabels.sectionScannedInventory,
              children: [
                _ScannedInventoryTable(
                  rows: controller.scannedRows.toList(growable: false),
                  busy: busy,
                  onRemove: controller.removeScannedRow,
                ),
              ],
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionMissingFromManifest,
            children: [
              _MissingFromManifestTable(
                rows: controller.missingRows.toList(growable: false),
                busy: busy,
                onNotPicked: controller.markNotPicked,
                onAddMissed: controller.addMissedShipment,
              ),
            ],
          ),
        ],
      );
    });
  }

  void _backToList() {
    Get.offNamed(Routes.OUTBOUND_SECTOR_PICKUP_LIST);
  }
}

class _SummaryStatsRow extends StatelessWidget {
  const _SummaryStatsRow({
    required this.manifested,
    required this.scanned,
    required this.missing,
  });

  final int manifested;
  final int scanned;
  final int missing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatChip(label: OutboundLabels.statManifested, value: manifested),
            _StatChip(label: OutboundLabels.statScanned, value: scanned),
            _StatChip(label: OutboundLabels.statMissing, value: missing),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: themes.fontSize14_500.copyWith(
            fontSize: 10.sp,
            color: themes.grayColor,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '$value',
          style: themes.fontSize18_600.copyWith(color: themes.darkCyanBlue),
        ),
      ],
    );
  }
}

class _ScannedInventoryTable extends StatelessWidget {
  const _ScannedInventoryTable({
    required this.rows,
    required this.busy,
    required this.onRemove,
  });

  final List<SectorPickupScannedRow> rows;
  final bool busy;
  final void Function(SectorPickupScannedRow row) onRemove;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No shipments scanned yet.',
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
            DataColumn(label: Text(OutboundLabels.colSealNo)),
            DataColumn(label: Text(OutboundLabels.colDocketNumber)),
            DataColumn(label: Text(OutboundLabels.colPkgs)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(_cell(row.sealNo))),
                    DataCell(Text(_cell(row.docketNo))),
                    DataCell(Text(_cell(row.pkgs))),
                    DataCell(
                      TextButton(
                        onPressed:
                            busy ? null : () => onRemove(row),
                        child: Text(
                          OutboundLabels.btnRemoveShipment,
                          style: themes.fontSize14_500.copyWith(
                            fontSize: 11.sp,
                            color: themes.redColor,
                          ),
                        ),
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

  static String _cell(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return '—';
    return t;
  }
}

class _MissingFromManifestTable extends StatelessWidget {
  const _MissingFromManifestTable({
    required this.rows,
    required this.busy,
    required this.onNotPicked,
    required this.onAddMissed,
  });

  final List<SectorPickupMissingRow> rows;
  final bool busy;
  final Future<void> Function(SectorPickupMissingRow row) onNotPicked;
  final Future<void> Function(SectorPickupMissingRow row) onAddMissed;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No missing shipments — scan MAWB to load manifest.',
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
          dataRowMinHeight: 52,
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 11.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text(OutboundLabels.colSealNo)),
            DataColumn(label: Text(OutboundLabels.colDocketNo)),
            DataColumn(label: Text(OutboundLabels.colStatus)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(_ScannedInventoryTable._cell(row.sealNo))),
                    DataCell(Text(_ScannedInventoryTable._cell(row.docketNo))),
                    DataCell(Text(_ScannedInventoryTable._cell(row.status))),
                    DataCell(
                      Wrap(
                        spacing: 4,
                        children: [
                          TextButton(
                            onPressed: busy ? null : () => onNotPicked(row),
                            child: Text(
                              OutboundLabels.btnMarkNotPicked,
                              style: themes.fontSize14_400.copyWith(
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: busy ? null : () => onAddMissed(row),
                            child: Text(
                              OutboundLabels.btnAddMissed,
                              style: themes.fontSize14_400.copyWith(
                                fontSize: 10.sp,
                              ),
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
