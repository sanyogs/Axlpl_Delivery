import 'package:axlpl_delivery/app/data/models/outbound/pickup_report_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_select_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/outbound_sector_pickup_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OutboundSectorPickupView extends GetView<OutboundSectorPickupController> {
  const OutboundSectorPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isBusy.value;
      final __ = controller.pickupRows.length;
      final ___ = controller.pickupReportRows.length;
      return OutboundScreen(
        title: 'Sector pickup',
        busy: busy,
        children: [
          OutboundSection(
            title: 'Pickup list (MAWB)',
            subtitle: OutboundLabels.subtitlePickupList,
            children: [
              OutboundPrimaryButton(
                title: 'Load pickup list',
                onPressed: busy ? null : controller.loadPickupList,
              ),
              _SectorPickupTable(
                rows: controller.pickupRows,
                busy: busy,
                onRowTap: controller.applyPickupIdFromRow,
              ),
            ],
          ),
          OutboundSection(
            title: 'Sector pickup scan',
            children: [
              OutboundField(
                controller: controller.pickupIdController,
                hintText: OutboundLabels.pickupId,
              ),
              OutboundScanField(
                controller: controller.docketController,
                hintText: OutboundLabels.shipmentNo,
              ),
              OutboundSelectField(
                label: OutboundLabels.scanStatus,
                value: controller.scanStatus.value,
                hint: OutboundLabels.selectStatus,
                options: OutboundSectorPickupController.scanStatusOptions,
                onChanged: (v) => controller.scanStatus.value = v,
              ),
              OutboundField(
                controller: controller.remarksController,
                hintText: OutboundLabels.remarks,
              ),
              OutboundPrimaryButton(
                title: 'Submit pickup scan',
                onPressed: busy ? null : controller.sectorPickupScan,
              ),
              OutboundButtonRow(
                start: OutboundSecondaryButton(
                  label: OutboundLabels.btnMarkNotPicked,
                  onPressed: busy ? null : controller.markNotPicked,
                ),
                end: OutboundSecondaryButton(
                  label: OutboundLabels.btnAddMissed,
                  onPressed: busy ? null : controller.addMissedShipment,
                ),
              ),
            ],
          ),
          OutboundSection(
            title: 'Pickup report',
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
                title: OutboundLabels.btnPickupReport,
                onPressed: busy ? null : controller.pickupReport,
              ),
              _PickupReportTable(rows: controller.pickupReportRows),
            ],
          ),
        ],
      );
    });
  }
}

class _SectorPickupTable extends StatelessWidget {
  const _SectorPickupTable({
    required this.rows,
    required this.busy,
    required this.onRowTap,
  });

  final List<SectorPickupRow> rows;
  final bool busy;
  final void Function(SectorPickupRow row) onRowTap;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No pickups — tap “Load pickup list”.',
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          columns: const [
            DataColumn(label: Text('Pickup id')),
            DataColumn(label: Text('MAWB')),
            DataColumn(label: Text('Hub')),
            DataColumn(label: Text('Date')),
          ],
          rows: rows
              .map(
                (e) => DataRow(
                  onSelectChanged: busy ? null : (_) => onRowTap(e),
                  cells: [
                    DataCell(Text(e.id ?? '—')),
                    DataCell(Text(e.mawbNo ?? '—')),
                    DataCell(Text(e.hubId ?? '—')),
                    DataCell(Text(e.pickupDate ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _PickupReportTable extends StatelessWidget {
  const _PickupReportTable({required this.rows});
  final List<PickupReportRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No report rows — generate report above.',
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Count')),
        ],
        rows: rows
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text(e.status ?? '—')),
                  DataCell(Text(e.count ?? '—')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
