import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_expandable_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/views/outbound_hub_scan_view.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Label / value row used in outbound detail cards (matches messenger list style).
class OutboundDetailField extends StatelessWidget {
  const OutboundDetailField({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty || value == '—') return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130.w,
            child: Text(
              label,
              style: themes.fontSize14_500.copyWith(color: themes.grayColor),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: themes.fontSize14_400,
            ),
          ),
        ],
      ),
    );
  }
}

String _outboundLocationLabel({
  String? apiName,
  String? id,
  required String Function(String? id) resolveId,
}) {
  final name = apiName?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (id == null || id.trim().isEmpty) return '—';
  return resolveId(id.trim());
}

String Function(String? id) _branchLabelResolver() {
  if (Get.isRegistered<OutboundBranchListController>()) {
    final c = Get.find<OutboundBranchListController>();
    return c.displayLabelForId;
  }
  return (id) => id?.trim().isNotEmpty == true ? id!.trim() : '—';
}

/// Full-screen / inline bag detail — header fields + `items[]` table.
class OutboundBagDetailBody extends StatelessWidget {
  const OutboundBagDetailBody({super.key, required this.detail});

  final BagDetail detail;

  @override
  Widget build(BuildContext context) {
    final count = detail.shipmentCount ?? detail.items.length;
    final branchLabel = _branchLabelResolver();
    final originLabel = _outboundLocationLabel(
      apiName: detail.originBranchName,
      id: detail.originBranchId,
      resolveId: branchLabel,
    );
    final destinationLabel = _outboundLocationLabel(
      apiName: detail.destinationSectorName,
      id: detail.destinationSectorId,
      resolveId: branchLabel,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        OutboundSection(
          title: 'Bag summary',
          subtitle: detail.bagCode ?? '',
          children: [
            OutboundDetailField(
              label: OutboundLabels.bagCode,
              value: detail.bagCode ?? '—',
            ),
            OutboundDetailField(
              label: OutboundLabels.metalSeal,
              value: detail.metalSealNo ?? '—',
            ),
            OutboundDetailField(
              label: OutboundLabels.manifestStatus,
              value: detail.manifestStatus ?? '—',
            ),
            OutboundDetailField(
              label: OutboundLabels.shipmentCount,
              value: count.toString(),
            ),
            OutboundDetailField(
              label: OutboundLabels.originDepot,
              value: originLabel,
            ),
            OutboundDetailField(
              label: OutboundLabels.destinationDepot,
              value: destinationLabel,
            ),
            OutboundDetailField(
              label: OutboundLabels.created,
              value: detail.createdAt ?? '—',
            ),
            OutboundDetailField(
              label: OutboundLabels.updated,
              value: detail.updatedAt ?? '—',
            ),
          ],
        ),
        OutboundSection(
          title: 'Shipments in bag',
          subtitle: count > 0 ? '$count shipment(s)' : 'No shipments loaded',
          children: [
            OutboundBagDetailItemsTable(items: detail.items),
          ],
        ),
      ],
    );
  }
}

/// Manifest detail — bags[] + shipments[] (one-to-many).
class OutboundManifestDetailBody extends StatelessWidget {
  const OutboundManifestDetailBody({
    super.key,
    required this.detail,
    this.compact = false,
  });

  final ManifestDetail detail;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final branchLabel = _branchLabelResolver();
    final originLabel = _outboundLocationLabel(
      apiName: detail.originBranchName,
      id: detail.originBranch,
      resolveId: branchLabel,
    );
    final destinationLabel = _outboundLocationLabel(
      apiName: detail.destinationBranchName,
      id: detail.destinationBranch,
      resolveId: branchLabel,
    );
    final summaryFields = [
      OutboundDetailField(
        label: OutboundLabels.manifestCode,
        value: detail.manifestNo ?? '—',
      ),
      OutboundDetailField(
        label: OutboundLabels.originDepot,
        value: originLabel,
      ),
      OutboundDetailField(
        label: OutboundLabels.destinationDepot,
        value: destinationLabel,
      ),
      OutboundDetailField(
        label: OutboundLabels.created,
        value: detail.createdAt ?? '—',
      ),
      if (!compact && (detail.updatedAt?.isNotEmpty ?? false))
        OutboundDetailField(
          label: OutboundLabels.updated,
          value: detail.updatedAt ?? '—',
        ),
    ];

    if (!compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          OutboundSection(
            title: 'Manifest summary',
            subtitle: detail.manifestNo ?? '',
            children: summaryFields,
          ),
          OutboundSection(
            title: 'Bags on manifest',
            subtitle: '${detail.bags.length} bag(s)',
            children: [
              OutboundManifestBagsTable(bags: detail.bags),
            ],
          ),
          OutboundSection(
            title: 'Shipments on manifest',
            subtitle: '${detail.shipments.length} shipment(s)',
            children: [
              OutboundManifestShipmentsTable(shipments: detail.shipments),
            ],
          ),
        ],
      );
    }

    return Card(
      elevation: 0,
      color: themes.lightGrayColor.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: summaryFields,
              ),
            ),
            if (detail.bags.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: 8.w),
                childrenPadding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
                title: Text(
                  'Bags (${detail.bags.length})',
                  style: themes.fontSize14_500,
                ),
                iconColor: themes.darkCyanBlue,
                collapsedIconColor: themes.darkCyanBlue,
                children: [
                  OutboundManifestBagsTable(bags: detail.bags),
                ],
              ),
            if (detail.shipments.isNotEmpty)
              ExpansionTile(
                tilePadding: EdgeInsets.symmetric(horizontal: 8.w),
                childrenPadding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.h),
                title: Text(
                  'Shipments (${detail.shipments.length})',
                  style: themes.fontSize14_500,
                ),
                iconColor: themes.darkCyanBlue,
                collapsedIconColor: themes.darkCyanBlue,
                children: [
                  OutboundManifestShipmentsTable(shipments: detail.shipments),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Linehaul trip detail (`getlinehauldetails` response).
class OutboundLinehaulDetailBody extends StatelessWidget {
  const OutboundLinehaulDetailBody({super.key, required this.detail});

  final LinehaulDetail detail;

  String _v(String? s) {
    final t = s?.trim();
    if (t == null || t.isEmpty) return '—';
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return OutboundSection(
      title: 'Linehaul summary',
      subtitle: detail.tripNo ?? detail.airwayBillNo ?? detail.linehaulId ?? '',
      children: [
        OutboundDetailField(
          label: OutboundLabels.tripNo,
          value: _v(detail.tripNo ?? detail.airwayBillNo ?? detail.mawbNo),
        ),
        OutboundDetailField(
          label: OutboundLabels.linehaulId,
          value: _v(detail.linehaulId),
        ),
        OutboundDetailField(
          label: OutboundLabels.originDepot,
          value: _v(detail.origin),
        ),
        OutboundDetailField(
          label: OutboundLabels.destinationDepot,
          value: _v(detail.destination),
        ),
        OutboundDetailField(
          label: 'Transport',
          value: _v(detail.transportType),
        ),
        OutboundDetailField(label: 'Airline', value: _v(detail.airline)),
        OutboundDetailField(label: 'Flight', value: _v(detail.flightNo)),
        OutboundDetailField(
          label: OutboundLabels.vehicleNo,
          value: _v(detail.vehicleNo),
        ),
        OutboundDetailField(
          label: OutboundLabels.driverName,
          value: _v(detail.driverName),
        ),
        OutboundDetailField(
          label: OutboundLabels.status,
          value: _v(detail.status),
        ),
        OutboundDetailField(
          label: 'No. of bags',
          value: _v(detail.noOfBags ?? detail.noOfBoxes),
        ),
        OutboundDetailField(
          label: 'Total weight',
          value: _v(detail.totalWeight),
        ),
        OutboundDetailField(
          label: 'Billing weight',
          value: _v(detail.totalBillingWeight),
        ),
        OutboundDetailField(
          label: 'Departure',
          value: _v(detail.departureTime),
        ),
        OutboundDetailField(
          label: 'Arrival',
          value: _v(detail.arrivalTime),
        ),
        if (detail.manifests.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            OutboundLabels.manifestNumbers,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          OutboundBoundedTableBox(
            maxHeight: 200,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Manifest')),
                  DataColumn(label: Text('Origin')),
                  DataColumn(label: Text('Destination')),
                  DataColumn(label: Text('Created')),
                ],
                rows: detail.manifests
                    .map(
                      (m) => DataRow(
                        cells: [
                          DataCell(Text(_v(m.manifestNo))),
                          DataCell(Text(_v(m.originBranch))),
                          DataCell(Text(_v(m.destinationBranch))),
                          DataCell(Text(_v(m.createdAt))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ] else
          OutboundDetailField(
            label: OutboundLabels.manifestNumbers,
            value: _v(detail.manifestCodes ?? detail.manifestIds),
          ),
      ],
    );
  }
}

class OutboundBagDetailItemsTable extends StatelessWidget {
  const OutboundBagDetailItemsTable({required this.items});
  final List<BagDetailItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 40,
          dataRowMaxHeight: 56,
          headingTextStyle: themes.fontSize14_500,
          columns: const [
            DataColumn(label: Text('Shipment')),
            DataColumn(label: Text('Invoice')),
            DataColumn(label: Text('Status')),
          ],
          rows: items
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(Text(e.shipmentId ?? '—')),
                    DataCell(Text(e.shipmentInvoiceNo ?? '—')),
                    DataCell(Text(e.shipmentStatus ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class OutboundManifestBagsTable extends StatelessWidget {
  const OutboundManifestBagsTable({required this.bags});
  final List<ManifestBagRef> bags;

  @override
  Widget build(BuildContext context) {
    if (bags.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 40,
          headingTextStyle: themes.fontSize14_500,
          columns: const [
            DataColumn(label: Text('Bag code')),
            DataColumn(label: Text('Metal seal')),
          ],
          rows: bags
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(Text(e.bagCode ?? '—')),
                    DataCell(Text(e.metalSealNo ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class OutboundManifestShipmentsTable extends StatelessWidget {
  const OutboundManifestShipmentsTable({required this.shipments});
  final List<ManifestShipmentRef> shipments;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
    }
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 40,
          headingTextStyle: themes.fontSize14_500,
          columns: const [
            DataColumn(label: Text('Shipment')),
            DataColumn(label: Text('Invoice')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Bag')),
          ],
          rows: shipments
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(Text(e.id ?? '—')),
                    DataCell(Text(e.shipmentInvoiceNo ?? '—')),
                    DataCell(Text(e.shipmentStatus ?? '—')),
                    DataCell(Text(e.bagCode ?? e.bagId ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
