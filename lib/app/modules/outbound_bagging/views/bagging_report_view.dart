import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Admin **Bagging Report** — bagging number + Print (PDF challan).
class BaggingReportView extends StatefulWidget {
  const BaggingReportView({super.key});

  @override
  State<BaggingReportView> createState() => _BaggingReportViewState();
}

class _BaggingReportViewState extends State<BaggingReportView> {
  late final OutboundBaggingController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundBaggingController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.prefillBaggingReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isBusy.value;
      return OutboundScreen(
        title: OutboundLabels.baggingReportTitle,
        busy: busy,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnPerformBagging,
              onPressed: () => Get.back(),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.baggingReportTitle,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.baggingNo,
                required: true,
                child: OutboundScanField(
                  controller: controller.reportBagCodeController,
                  hintText: OutboundLabels.hintBaggingNo,
                  prefixIcon: const Icon(CupertinoIcons.cube_box),
                  onSubmitted: (_) => controller.printBaggingReport(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: OutboundPrimaryButton(
                  title: OutboundLabels.btnPrint,
                  onPressed: busy ? null : controller.printBaggingReport,
                ),
              ),
            ],
          ),
        ],
      );
    });
  }
}
