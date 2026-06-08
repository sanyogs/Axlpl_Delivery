import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_manifest/controllers/outbound_manifest_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class ManifestReportView extends StatefulWidget {
  const ManifestReportView({super.key});

  @override
  State<ManifestReportView> createState() => _ManifestReportViewState();
}

class _ManifestReportViewState extends State<ManifestReportView> {
  late final OutboundManifestController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundManifestController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.prefillManifestReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final busy = controller.isBusy.value;
      final report = controller.manifestReportData.value;
      final bags = report?.bags ?? [];
      final shipments = report?.shipments ?? [];

      return OutboundScreen(
        title: OutboundLabels.manifestReportTitle,
        busy: busy,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnPerformManifest,
              onPressed: () => Get.back(),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.manifestReportTitle,
            children: [
              Text(
                OutboundLabels.subtitleManifestReport,
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
                label: OutboundLabels.manifestCode,
                child: OutboundScanField(
                  controller: controller.reportManifestCodeController,
                  hintText: OutboundLabels.manifestCodeOptional,
                  prefixIcon: const Icon(CupertinoIcons.doc_text),
                ),
              ),
              OutboundPrimaryButton(
                title: OutboundLabels.btnManifestReport,
                onPressed: busy ? null : controller.manifestReport,
              ),
              if (report != null && _hasReportHeader(report)) ...[
                SizedBox(height: 4.h),
                _ManifestReportSummary(report: report),
              ],
              if (bags.isNotEmpty)
                OutboundSection(
                  title: OutboundLabels.sectionMBagDetails,
                  subtitle: '${bags.length} bag(s)',
                  children: [
                    _ManifestReportBagsTable(bags: bags),
                  ],
                ),
              OutboundSection(
                title: OutboundLabels.sectionManifestShipmentDetails,
                subtitle: shipments.isEmpty
                    ? 'No shipments returned'
                    : '${shipments.length} shipment(s)',
                children: [
                  _ManifestReportShipmentsTable(shipments: shipments),
                ],
              ),
            ],
          ),
        ],
      );
    });
  }
}

bool _hasReportHeader(ManifestReport report) {
  return (report.manifestNo?.isNotEmpty ?? false) ||
      (report.originBranchName?.isNotEmpty ?? false) ||
      (report.destinationBranchName?.isNotEmpty ?? false);
}

class _ManifestReportSummary extends StatelessWidget {
  const _ManifestReportSummary({required this.report});

  final ManifestReport report;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutboundDetailField(
          label: OutboundLabels.manifestCode,
          value: report.manifestNo ?? '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.originDepot,
          value: report.originName ??
              report.originBranchName ??
              report.originBranch ??
              '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.destinationDepot,
          value: report.destinationName ??
              report.destinationBranchName ??
              report.destinationBranch ??
              '—',
        ),
        OutboundDetailField(
          label: OutboundLabels.created,
          value: report.createdAt ?? '—',
        ),
      ],
    );
  }
}

class _ManifestReportBagsTable extends StatelessWidget {
  const _ManifestReportBagsTable({required this.bags});

  final List<ManifestBagRef> bags;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text(OutboundLabels.colSlNo)),
          DataColumn(label: Text(OutboundLabels.bagCode)),
          DataColumn(label: Text(OutboundLabels.metalSeal)),
          DataColumn(label: Text(OutboundLabels.colWeight)),
        ],
        rows: [
          for (var i = 0; i < bags.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(bags[i].bagCode ?? '—')),
                DataCell(Text(bags[i].metalSealNo ?? '—')),
                DataCell(Text(bags[i].grossWeight ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}

class _ManifestReportShipmentsTable extends StatelessWidget {
  const _ManifestReportShipmentsTable({required this.shipments});

  final List<ManifestShipmentRef> shipments;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return Text(
        OutboundLabels.manifestShipmentTableEmpty,
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text(OutboundLabels.colSlNo)),
          DataColumn(label: Text(OutboundLabels.colConsignmentNo)),
          DataColumn(label: Text(OutboundLabels.colConsigneeName)),
          DataColumn(label: Text(OutboundLabels.colCityName)),
          DataColumn(label: Text(OutboundLabels.connoteWeight)),
          DataColumn(label: Text(OutboundLabels.conVolWeight)),
        ],
        rows: [
          for (var i = 0; i < shipments.length; i++)
            DataRow(
              cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(shipments[i].id ?? '—')),
                DataCell(
                  Text(
                    shipments[i].receiverName ?? shipments[i].senderName ?? '—',
                  ),
                ),
                DataCell(Text(shipments[i].destinationCity ?? '—')),
                DataCell(Text(shipments[i].grossWeight ?? '—')),
                DataCell(Text(shipments[i].volumetricWeight ?? '—')),
              ],
            ),
        ],
      ),
    );
  }
}
