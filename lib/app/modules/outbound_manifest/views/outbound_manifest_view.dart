import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dynamic_map_table.dart';
import 'package:axlpl_delivery/app/modules/outbound_manifest/controllers/outbound_manifest_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundManifestView extends GetView<OutboundManifestController> {
  const OutboundManifestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themes.lightWhite,
      appBar: AppBar(
        title: const Text('Manifest'),
        backgroundColor: themes.whiteColor,
      ),
      body: Obx(() {
        final busy = controller.isBusy.value;
        final _ = controller.lastResponseText.value;
        final __ = controller.manifestRows.length;
        return AbsorbPointer(
          absorbing: busy,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Create manifest',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: controller.bagIdsController,
                decoration: const InputDecoration(
                  labelText: 'Bag ids (comma-separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.originBranchController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Origin branch id',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.destBranchController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Destination branch id',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.createManifest,
                child: const Text('Create manifest'),
              ),
              const Divider(height: 24),
              TextField(
                controller: controller.listBranchController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Branch id (list)',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.listManifests,
                child: const Text('List manifests'),
              ),
              const SizedBox(height: 8),
              OutboundDynamicMapTable(
                title: 'Manifests (tap row to fill manifest id)',
                rows: controller.listRows,
                onRowTap: busy ? null : controller.applyManifestIdFromListRow,
              ),
              const Divider(height: 24),
              TextField(
                controller: controller.manifestIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Manifest id',
                  border: OutlineInputBorder(),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: busy ? null : controller.getManifestDetails,
                    child: const Text('Details'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : controller.openManifestDetailPage,
                    child: const Text('Full-screen detail'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : controller.printManifestData,
                    child: const Text('Print data'),
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
                onPressed: busy ? null : controller.manifestReport,
                child: const Text('Manifest report'),
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
