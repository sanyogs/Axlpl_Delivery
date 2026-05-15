import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/outbound_sector_pickup_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundSectorPickupView extends GetView<OutboundSectorPickupController> {
  const OutboundSectorPickupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themes.lightWhite,
      appBar: AppBar(
        title: const Text('Sector pickup'),
        backgroundColor: themes.whiteColor,
      ),
      body: Obx(() {
        final busy = controller.isBusy.value;
        final _ = controller.lastResponseText.value;
        final __ = controller.pickupRows.length;
        return AbsorbPointer(
          absorbing: busy,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ElevatedButton(
                onPressed: busy ? null : controller.loadPickupList,
                child: const Text('Get pickup list'),
              ),
              const SizedBox(height: 12),
              Text(
                'Pickup list (${controller.pickupRows.length})',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _SectorPickupTable(
                rows: controller.pickupRows,
                busy: busy,
                onRowTap: controller.applyPickupIdFromRow,
              ),
              const Divider(height: 24),
              TextField(
                controller: controller.pickupIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pickup id',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.docketController,
                decoration: const InputDecoration(
                  labelText: 'Shipment no (docket)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.scanStatusController,
                decoration: const InputDecoration(
                  labelText: 'Scan status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: busy ? null : controller.sectorPickupScan,
                    child: const Text('Pickup scan'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : controller.markNotPicked,
                    child: const Text('Mark not picked'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : controller.addMissedShipment,
                    child: const Text('Add missed shipment'),
                  ),
                ],
              ),
              const Divider(height: 24),
              TextField(
                controller: controller.reportStartController,
                decoration: const InputDecoration(
                  labelText: 'Report start YYYY-MM-DD',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.reportEndController,
                decoration: const InputDecoration(
                  labelText: 'Report end YYYY-MM-DD',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.pickupReport,
                child: const Text('Pickup report'),
              ),
              const SizedBox(height: 16),
              if (busy) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text(
                'Last response',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              SelectableText(controller.lastResponseText.value),
            ],
          ),
        );
      }),
    );
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
      return const Text('No rows yet — tap “Get pickup list”.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 64,
        columns: const [
          DataColumn(label: Text('Pickup id')),
          DataColumn(label: Text('MAWB')),
          DataColumn(label: Text('Hub')),
          DataColumn(label: Text('Picked by')),
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Time')),
        ],
        rows: rows
            .map(
              (e) => DataRow(
                onSelectChanged: busy
                    ? null
                    : (_) {
                        onRowTap(e);
                        Get.snackbar(
                          'Sector pickup',
                          'Pickup id ${e.id ?? ''} copied to field',
                        );
                      },
                cells: [
                  DataCell(Text(e.id ?? '—')),
                  DataCell(Text(e.mawbNo ?? '—')),
                  DataCell(Text(e.hubId ?? '—')),
                  DataCell(Text(e.pickedBy ?? '—')),
                  DataCell(Text(e.pickupDate ?? '—')),
                  DataCell(Text(e.pickupTime ?? '—')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
