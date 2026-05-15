import 'package:axlpl_delivery/app/modules/outbound_remote_detail/controllers/outbound_remote_detail_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundRemoteDetailView extends GetView<OutboundRemoteDetailController> {
  const OutboundRemoteDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themes.lightWhite,
      appBar: AppBar(
        title: Obx(() => Text(controller.title.value)),
        backgroundColor: themes.whiteColor,
        actions: [
          Obx(
            () => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: controller.isLoading.value ? null : controller.reload,
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SelectionArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.summaryLines.isNotEmpty) ...[
                    Text(
                      'Summary',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: themes.whiteColor,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: controller.summaryLines
                              .map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: SelectableText(line),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    'Raw response',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    controller.detailText.value,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
