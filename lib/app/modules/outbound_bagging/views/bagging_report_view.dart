import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_section.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

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
                OutboundLabels.subtitleBaggingReport,
                style: themes.fontSize14_400.copyWith(color: themes.grayColor),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.reportStart,
                child: OutboundDateField(
                  controller: controller.reportStartController,
                  hintText: OutboundLabels.reportStart,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.reportEnd,
                child: OutboundDateField(
                  controller: controller.reportEndController,
                  hintText: OutboundLabels.reportEnd,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.bagCode,
                child: OutboundScanField(
                  controller: controller.reportBagCodeController,
                  hintText: OutboundLabels.bagCode,
                  prefixIcon: const Icon(CupertinoIcons.cube_box),
                  onSubmitted: (_) => controller.baggingReport(),
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
                title: OutboundLabels.sectionScannedBoxes,
                subtitle: items.isEmpty
                    ? 'No shipments returned'
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
      return Text(
        'Run report with dates or a bag code to load shipments.',
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text(OutboundLabels.colSlNo)),
          DataColumn(label: Text(OutboundLabels.colShipmentId)),
          DataColumn(label: Text(OutboundLabels.colInvoiceNo)),
          DataColumn(label: Text(OutboundLabels.receiverName)),
          DataColumn(label: Text(OutboundLabels.colDestination)),
          DataColumn(label: Text(OutboundLabels.boxWeight)),
          DataColumn(label: Text(OutboundLabels.noOfBox)),
        ],
        rows: [
          for (var i = 0; i < items.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(items[i].shipmentId ?? '—')),
                DataCell(Text(items[i].shipmentInvoiceNo ?? '—')),
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
