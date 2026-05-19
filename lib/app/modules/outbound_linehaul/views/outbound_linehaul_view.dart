import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_response_panel.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_select_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/views/outbound_hub_scan_view.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/outbound_linehaul_controller.dart';
import 'package:axlpl_delivery/common_widget/common_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundLinehaulView extends GetView<OutboundLinehaulController> {
  const OutboundLinehaulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isBusy.value;
      final _ = controller.lastResponseText.value;
      final __ = controller.linehaulRows.length;
      final ___ = controller.linehaulDetail.value;
      return OutboundScreen(
        title: 'Linehaul',
        busy: busy,
        children: [
          OutboundSection(
            title: 'Assign linehaul',
            subtitle:
                'manifest_codes, vehicle_no, driver_name, user_id (multipart POST)',
            children: [
              OutboundScanField(
                controller: controller.manifestCodesController,
                hintText: OutboundLabels.manifestCodesCsv,
              ),
              OutboundField(
                controller: controller.vehicleController,
                hintText: OutboundLabels.vehicleNo,
              ),
              OutboundField(
                controller: controller.driverController,
                hintText: OutboundLabels.driverName,
              ),
              CommonButton(
                title: 'Assign linehaul',
                onPressed: busy ? null : controller.assignLinehaul,
              ),
            ],
          ),
          OutboundSection(
            title: 'Linehaul list',
            children: [
              OutboundSelectField(
                label: OutboundLabels.linehaulFilterStatus,
                value: controller.listFilterStatus.value,
                options: OutboundLinehaulController.listStatusOptions,
                onChanged: (v) => controller.listFilterStatus.value = v,
              ),
              CommonButton(
                title: 'List linehauls',
                onPressed: busy ? null : controller.listLinehauls,
              ),
              _LinehaulListTable(
                rows: controller.linehaulRows,
                onRowTap: busy ? null : controller.applyLinehaulFromRow,
              ),
            ],
          ),
          OutboundSection(
            title: 'Linehaul detail & status',
            children: [
              OutboundScanField(
                controller: controller.tripNoController,
                hintText: OutboundLabels.tripNo,
              ),
              OutlinedButton(
                onPressed: busy ? null : controller.getLinehaulDetails,
                child: const Text('Linehaul details'),
              ),
              if (controller.linehaulDetail.value != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Trip ${controller.linehaulDetail.value?.tripNo ?? ''} · '
                    '${controller.linehaulDetail.value?.status ?? ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              OutlinedButton(
                onPressed: busy ? null : controller.openLinehaulDetailPage,
                child: const Text('Full-screen detail'),
              ),
              OutboundSelectField(
                label: OutboundLabels.newLinehaulStatus,
                value: controller.updateStatus.value,
                options: OutboundLinehaulController.updateStatusOptions,
                onChanged: (v) => controller.updateStatus.value = v,
              ),
              CommonButton(
                title: 'Update linehaul status',
                onPressed: busy ? null : controller.updateLinehaulStatus,
              ),
            ],
          ),
          OutboundSection(
            title: 'Linehaul report',
            children: [
              OutboundDateField(
                controller: controller.reportStartController,
                hintText: OutboundLabels.reportStart,
              ),
              OutboundDateField(
                controller: controller.reportEndController,
                hintText: OutboundLabels.reportEnd,
              ),
              CommonButton(
                title: 'Generate linehaul report',
                onPressed: busy ? null : controller.linehaulReport,
              ),
            ],
          ),
          OutboundResponsePanel(text: controller.lastResponseText.value),
        ],
      );
    });
  }
}

class _LinehaulListTable extends StatelessWidget {
  const _LinehaulListTable({
    required this.rows,
    this.onRowTap,
  });

  final List<OutboundLinehaulRow> rows;
  final void Function(OutboundLinehaulRow row)? onRowTap;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Trip no')),
          DataColumn(label: Text('Vehicle')),
          DataColumn(label: Text('Driver')),
          DataColumn(label: Text('Status')),
        ],
        rows: rows
            .map(
              (e) => DataRow(
                onSelectChanged:
                    onRowTap == null ? null : (_) => onRowTap!(e),
                cells: [
                  DataCell(Text(e.tripNo ?? e.linehaulId ?? '—')),
                  DataCell(Text(e.vehicleNo ?? '—')),
                  DataCell(Text(e.driverName ?? '—')),
                  DataCell(Text(e.status ?? '—')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
