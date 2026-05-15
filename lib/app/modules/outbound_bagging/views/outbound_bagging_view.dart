import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dynamic_map_table.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundBaggingView extends GetView<OutboundBaggingController> {
  const OutboundBaggingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themes.lightWhite,
      appBar: AppBar(
        title: const Text('Bagging'),
        backgroundColor: themes.whiteColor,
      ),
      body: Obx(() {
        final busy = controller.isBusy.value;
        final _ = controller.lastResponseText.value;
        final __ = controller.bagRows.length;
        return AbsorbPointer(
          absorbing: busy,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Create bag',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 8),
              TextField(
                controller: controller.bagCodeController,
                decoration: const InputDecoration(
                  labelText: 'Bag code',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.createBag,
                child: const Text('Create bag'),
              ),
              const Divider(height: 24),
              const Text('Working bag + docket',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: controller.bagIdController,
                decoration: const InputDecoration(
                  labelText: 'Bag id / bag code (from list)',
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: busy ? null : controller.addShipment,
                    child: const Text('Add to bag'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : controller.removeShipment,
                    child: const Text('Remove'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : controller.getBagDetails,
                    child: const Text('Bag details'),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : controller.openBagDetailPage,
                    child: const Text('Full-screen detail'),
                  ),
                  ElevatedButton(
                    onPressed: busy ? null : controller.lockBag,
                    child: const Text('Lock bag'),
                  ),
                ],
              ),
              TextField(
                controller: controller.newBagIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New bag id (rebag)',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.rebag,
                child: const Text('Rebag shipment'),
              ),
              const Divider(height: 24),
              ElevatedButton(
                onPressed: busy ? null : controller.listBags,
                child: const Text('List bags (uses origin branch id)'),
              ),
              const SizedBox(height: 8),
              OutboundDynamicMapTable(
                title: 'Bags (tap row to fill bag id)',
                rows: controller.listRows,
                onRowTap: busy ? null : controller.applyBagIdFromListRow,
              ),
              const Divider(height: 24),
              const Text('Bagging report',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              TextField(
                controller: controller.reportStartController,
                decoration: const InputDecoration(
                  labelText: 'Start YYYY-MM-DD',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.reportEndController,
                decoration: const InputDecoration(
                  labelText: 'End YYYY-MM-DD',
                  border: OutlineInputBorder(),
                ),
              ),
              ElevatedButton(
                onPressed: busy ? null : controller.baggingReport,
                child: const Text('Bagging report'),
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
