import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_log_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/shipment_scan_event_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_branch_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_response_panel.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_select_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/controllers/outbound_hub_scan_controller.dart';
import 'package:axlpl_delivery/common_widget/common_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundHubScanView extends GetView<OutboundHubScanController> {
  const OutboundHubScanView({super.key});

  @override
  Widget build(BuildContext context) {
    final branchList = Get.find<OutboundBranchListController>();
    return Obx(() {
      final busy = controller.isBusy.value;
      final _ = controller.lastResponseText.value;
      final __ = controller.shipmentHintText.value;
      final ___ = branchList.branches.length;
      final ____ = branchList.selectedBranchId.value;
      return OutboundScreen(
        title: 'Hub scan',
        busy: busy,
        children: [
          OutboundSection(
            title: 'Scan shipment',
            subtitle: 'Scan docket at hub (Save on admin)',
            children: [
              OutboundScanField(
                controller: controller.docketController,
                hintText: OutboundLabels.docketNo,
                prefixIcon: const Icon(CupertinoIcons.doc_text_search),
              ),
              Obx(
                () => OutboundBranchSelect(
                  label: OutboundLabels.branchHub,
                  items: branchList.branches,
                  selectedId: branchList.selectedBranchId.value,
                  isLoading: branchList.isLoadingBranches.value,
                  onChanged: (id) {
                    branchList.onBranchSelected(id);
                    branchList.showLoadIssueIfNeeded();
                  },
                ),
              ),
              OutboundSelectField(
                label: OutboundLabels.hubScanStatus,
                value: controller.status.value,
                options: controller.statuses,
                onChanged: (v) => controller.status.value = v,
              ),
              CommonButton(
                title: 'Submit hub scan',
                onPressed: busy ? null : controller.submitHubScan,
              ),
              OutlinedButton(
                onPressed: busy ? null : controller.loadShipmentHint,
                child: const Text('Load shipment details'),
              ),
              if (controller.shipmentHintText.value.isNotEmpty)
                OutboundResponsePanel(
                  title: 'Shipment details',
                  text: controller.shipmentHintText.value,
                ),
            ],
          ),
          OutboundSection(
            title: 'Hub scan logs',
            children: [
              OutboundField(
                controller: controller.hubScanLimit,
                hintText: OutboundLabels.logLimit,
                keyboardType: TextInputType.number,
              ),
              CommonButton(
                title: 'Refresh hub scan logs',
                onPressed: busy ? null : controller.loadHubScanLogs,
              ),
              _HubScanLogsTable(rows: controller.hubScanLogs),
            ],
          ),
          OutboundSection(
            title: 'Shipment scan history',
            subtitle: 'GET getshipmentscanhistory — same docket as hub scan',
            children: [
              OutboundScanField(
                controller: controller.scanHistoryDocketController,
                hintText: OutboundLabels.docketNo,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : controller.useScanDocketForHistory,
                      child: const Text('Use scan docket'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CommonButton(
                      title: 'Get scan history',
                      onPressed: busy ? null : controller.loadShipmentScanHistory,
                    ),
                  ),
                ],
              ),
              _ShipmentHistoryTable(rows: controller.shipmentHistory),
            ],
          ),
          OutboundResponsePanel(text: controller.lastResponseText.value),
        ],
      );
    });
  }
}

class _HubScanLogsTable extends StatelessWidget {
  const _HubScanLogsTable({required this.rows});
  final List<HubScanLog> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Docket / shipment')),
          DataColumn(label: Text('Invoice / box')),
          DataColumn(label: Text('Scan')),
          DataColumn(label: Text('Branch')),
          DataColumn(label: Text('Scanned at')),
        ],
        rows: rows
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text(e.shipmentId ?? '—')),
                  DataCell(Text(e.shipmentInvoiceNo ?? e.boxNo ?? '—')),
                  DataCell(Text(e.scanType ?? '—')),
                  DataCell(Text(e.branchId ?? '—')),
                  DataCell(Text(e.scannedAt ?? '—')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ShipmentHistoryTable extends StatelessWidget {
  const _ShipmentHistoryTable({required this.rows});
  final List<ShipmentScanEvent> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Docket')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Branch')),
          DataColumn(label: Text('When')),
          DataColumn(label: Text('Remark')),
        ],
        rows: rows
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text(e.shipmentId ?? '—')),
                  DataCell(Text(e.status ?? '—')),
                  DataCell(Text(e.branchId ?? '—')),
                  DataCell(Text(e.createdDate ?? '—')),
                  DataCell(Text(e.remark ?? '')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Avoid importing map table for empty state in nested tables.
class OutboundDynamicMapTablePlaceholder extends StatelessWidget {
  const OutboundDynamicMapTablePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'No rows loaded yet.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
    );
  }
}
