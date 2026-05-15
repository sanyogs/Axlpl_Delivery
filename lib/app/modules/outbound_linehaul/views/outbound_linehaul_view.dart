import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dynamic_map_table.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/outbound_linehaul_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundLinehaulView extends GetView<OutboundLinehaulController> {
  const OutboundLinehaulView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themes.lightWhite,
      appBar: AppBar(
        title: const Text('Linehaul'),
        backgroundColor: themes.whiteColor,
      ),
      body: Obx(() {
        final busy = controller.isBusy.value;
        final _ = controller.lastResponseText.value;
        final __ = controller.linehaulRows.length;
        return AbsorbPointer(
          absorbing: busy,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Assign linehaul',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: controller.manifestIdsController,
                decoration: const InputDecoration(
                  labelText: 'Manifest ids (comma-separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Vehicle no',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.driverController,
                decoration: const InputDecoration(
                  labelText: 'Driver name',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.assignLinehaul,
                child: const Text('Assign linehaul'),
              ),
              const Divider(height: 24),
              TextField(
                controller: controller.listStatusController,
                decoration: const InputDecoration(
                  labelText: 'List filter status',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.listLinehauls,
                child: const Text('List linehauls'),
              ),
              const SizedBox(height: 8),
              OutboundDynamicMapTable(
                title: 'Linehauls (tap row to fill linehaul id)',
                rows: controller.listRows,
                onRowTap: busy ? null : controller.applyLinehaulIdFromListRow,
              ),
              const Divider(height: 24),
              TextField(
                controller: controller.linehaulIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Linehaul id',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.getLinehaulDetails,
                child: const Text('Linehaul details'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy ? null : controller.openLinehaulDetailPage,
                child: const Text('Full-screen detail'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.updateStatusController,
                decoration: const InputDecoration(
                  labelText: 'New status (e.g. ARRIVED)',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.updateLinehaulStatus,
                child: const Text('Update linehaul status'),
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
                onPressed: busy ? null : controller.linehaulReport,
                child: const Text('Linehaul report'),
              ),
              const SizedBox(height: 16),
              if (busy) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text('Last response',
                  style: Theme.of(context).textTheme.titleSmall),
              SelectableText(controller.lastResponseText.value),
            ],
          ),
        );
      }),
    );
  }
}
