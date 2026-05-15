import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_log_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/shipment_scan_event_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/controllers/outbound_hub_scan_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundHubScanView extends GetView<OutboundHubScanController> {
  const OutboundHubScanView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themes.lightWhite,
      appBar: AppBar(
        title: const Text('Hub scan'),
        backgroundColor: themes.whiteColor,
      ),
      body: Obx(() {
        final busy = controller.isBusy.value;
        final _ = controller.lastResponseText.value;
        final __ = controller.status.value;
        final ___ = controller.hubScanLogs.length;
        final ____ = controller.shipmentHistory.length;
        final _____ = controller.shipmentHintText.value;
        return AbsorbPointer(
          absorbing: busy,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: controller.docketController,
                decoration: const InputDecoration(
                  labelText: 'Docket no',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller.branchController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Branch id',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: controller.status.value,
                decoration: const InputDecoration(
                  labelText: 'Scan status',
                  border: OutlineInputBorder(),
                ),
                items: controller.statuses
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.status.value = v;
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: busy ? null : controller.submitHubScan,
                    child: const Text('Hub scan (POST)'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : controller.loadShipmentHint,
                    child: const Text('Shipment hint (consignment)'),
                  ),
                ],
              ),
              if (controller.shipmentHintText.value.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Shipment hint',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SelectableText(controller.shipmentHintText.value),
              ],
              const Divider(height: 32),
              TextField(
                controller: controller.hubScanLimit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Log limit',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: busy ? null : controller.loadHubScanLogs,
                child: const Text('Get hub scan logs'),
              ),
              const SizedBox(height: 12),
              Text(
                'Hub scan logs',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _HubScanLogsTable(rows: controller.hubScanLogs),
              const Divider(height: 32),
              TextField(
                controller: controller.scanHistoryDocketController,
                decoration: const InputDecoration(
                  labelText: 'Docket for scan history',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: busy ? null : controller.loadShipmentScanHistory,
                child: const Text('Get shipment scan history'),
              ),
              const SizedBox(height: 12),
              Text(
                'Shipment scan history',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _ShipmentHistoryTable(rows: controller.shipmentHistory),
              const SizedBox(height: 24),
              if (busy) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Last submit / summary',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SelectableText(controller.lastResponseText.value),
            ],
          ),
        );
      }),
    );
  }
}

class _HubScanLogsTable extends StatelessWidget {
  const _HubScanLogsTable({required this.rows});

  final List<HubScanLog> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Text('No rows loaded.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 64,
        columns: const [
          DataColumn(label: Text('Invoice / box')),
          DataColumn(label: Text('Scan')),
          DataColumn(label: Text('Branch')),
          DataColumn(label: Text('Scanned at')),
        ],
        rows: rows
            .map(
              (e) => DataRow(
                cells: [
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
      return const Text('No rows loaded.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 72,
        columns: const [
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Branch')),
          DataColumn(label: Text('When')),
          DataColumn(label: Text('Remark')),
        ],
        rows: rows
            .map(
              (e) => DataRow(
                cells: [
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
