import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/views/outbound_hub_scan_view.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// `baggingreport` — Postman: `start_date` + `end_date`; QA: optional `bag_code` for bag detail.
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
      final report = controller.baggingReportData.value;
      final items = report?.items ?? [];
      final _ = controller.baggingReportData.value;

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
              Text(
                'Dates → start_date & end_date. Bag code → bag_code (detail).',
                style: themes.fontSize14_400.copyWith(color: themes.grayColor),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.reportStart,
                required: true,
                child: OutboundDateField(
                  controller: controller.reportStartController,
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.reportEnd,
                required: true,
                child: OutboundDateField(
                  controller: controller.reportEndController,
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.bagCode,
                child: OutboundField(
                  controller: controller.reportBagCodeController,
                  hintText: 'Optional BAG… (overrides dates)',
                  prefixIcon: const Icon(CupertinoIcons.barcode),
                ),
              ),
              OutboundPrimaryButton(
                title: OutboundLabels.btnBaggingReport,
                onPressed: busy ? null : controller.baggingReport,
              ),
              if (report != null && _hasReportHeader(report)) ...[
                SizedBox(height: 4.h),
                _BaggingReportSummary(report: report),
              ],
              OutboundSection(
                title: 'Shipments in bag',
                subtitle: items.isEmpty
                    ? 'No shipments in report'
                    : '${items.length} shipment(s)',
                children: [
                  _BaggingReportItemsTable(items: items),
                ],
              ),
            ],
          ),
        ],
      );
    });
  }
}

bool _hasReportHeader(BaggingReport report) {
  return (report.bagCode?.isNotEmpty ?? false) ||
      (report.metalSealNo?.isNotEmpty ?? false) ||
      (report.originBranchName?.isNotEmpty ?? false) ||
      (report.destinationCityName?.isNotEmpty ?? false);
}

class _BaggingReportSummary extends StatelessWidget {
  const _BaggingReportSummary({required this.report});

  final BaggingReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutboundDetailField(
          label: OutboundLabels.bagCode,
          value: report.bagCode ?? '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.metalSeal,
          value: report.metalSealNo ?? '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.originDepot,
          value: report.originBranchName ?? report.originBranchId ?? '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.destCity,
          value: report.destinationCityName ?? report.destinationSectorId ?? '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.created,
          value: report.createdAt ?? '—',
        ),
      ],
    );
  }
}

class _BaggingReportItemsTable extends StatelessWidget {
  const _BaggingReportItemsTable({required this.items});
  final List<BaggingReportItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text(OutboundLabels.colSlNo)),
          DataColumn(label: Text(OutboundLabels.colShipmentId)),
          DataColumn(label: Text(OutboundLabels.receiverName)),
          DataColumn(label: Text(OutboundLabels.colDestination)),
          DataColumn(label: Text('WEIGHT (KG)')),
          DataColumn(label: Text('PKGS')),
        ],
        rows: [
          for (var i = 0; i < items.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(items[i].shipmentId ?? '—')),
                DataCell(Text(items[i].receiverName ?? items[i].senderName ?? '—')),
                DataCell(Text(items[i].destinationCity ?? '—')),
                DataCell(Text(items[i].totalWeight ?? '—')),
                DataCell(Text(items[i].noOfPackage ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}
