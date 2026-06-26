import 'package:axlpl_delivery/app/data/models/outbound/pickup_detail_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/sector_pickup_report_show_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin sector pickup **show report** — `getpickupdetail` preview + PDF print.
class SectorPickupReportShowView extends GetView<SectorPickupReportShowController> {
  const SectorPickupReportShowView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final printing = controller.isPrinting.value;
      final err = controller.errorMessage.value.trim();
      final detail = controller.detail.value;
      final groups = controller.bagGroups;

      return OutboundScreen(
        title: OutboundLabels.sectorPickupReportTitle,
        busy: printing,
        onRefresh: loading
            ? null
            : () async {
                await controller.load();
              },
        children: [
          if (loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Center(
                child: CircularProgressIndicator(color: themes.darkCyanBlue),
              ),
            )
          else if (err.isNotEmpty)
            Column(
              children: [
                Text(
                  err,
                  textAlign: TextAlign.center,
                  style: themes.fontSize14_400.copyWith(color: themes.redColor),
                ),
                SizedBox(height: 12.h),
                OutboundSecondaryButton(
                  label: 'Retry',
                  onPressed: () => controller.load(),
                ),
              ],
            )
          else if (detail != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutboundAdminSection(
                  title: OutboundLabels.sectorPickupReportTitle,
                  children: [
                    Text(
                      'Transaction ID- SGP ${_cell(detail.id)}',
                      style: themes.fontSize14_500.copyWith(
                        color: themes.darkCyanBlue,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    OutboundDetailField(
                      label: OutboundLabels.mawbNo,
                      value: detail.mawbNo ?? '—',
                      copyable: true,
                      snackbarTitle: 'Sector pickup',
                    ),
                    OutboundDetailField(
                      label: OutboundLabels.pickedBy,
                      value: detail.pickedBy?.trim().isNotEmpty == true
                          ? detail.pickedBy!.trim()
                          : 'N/A',
                    ),
                    OutboundDetailField(
                      label: OutboundLabels.colHubBranch,
                      value: detail.hubBranchLabel,
                    ),
                    OutboundDetailField(
                      label: OutboundLabels.pickupDate,
                      value: detail.pickupDateTimeLabel,
                    ),
                    OutboundDetailField(
                      label: OutboundLabels.created,
                      value: detail.createdAt ?? '—',
                    ),
                    OutboundDetailField(
                      label: OutboundLabels.statManifested,
                      value: '${detail.manifestedCount} Shipments',
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                OutboundAdminSection(
                  title: OutboundLabels.sectionPickupDetailsReceived,
                  children: [
                    _PickupReportTable(groups: groups),
                  ],
                ),
                SizedBox(height: 16.h),
                OutboundButtonRow(
                  start: OutboundSecondaryButton(
                    label: OutboundLabels.btnShowList,
                    onPressed: printing ? null : () => Get.back(),
                  ),
                  end: OutboundPrimaryButtonCompact(
                    title: OutboundLabels.btnPrintPickupReport,
                    onPressed: printing ? null : controller.printReport,
                    isLoading: printing,
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }

  static String _cell(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return '—';
    return t;
  }
}

class _PickupReportTable extends StatelessWidget {
  const _PickupReportTable({required this.groups});

  final List<SectorPickupReportBagGroup> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Text(
        OutboundLabels.sectorPickupReportEmpty,
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        headingTextStyle: themes.fontSize14_500.copyWith(
          fontSize: 11.sp,
          color: themes.grayColor,
        ),
        columns: const [
          DataColumn(label: Text(OutboundLabels.colSlNo)),
          DataColumn(label: Text(OutboundLabels.colBagSealAndCode)),
          DataColumn(label: Text(OutboundLabels.colDestHub)),
          DataColumn(label: Text(OutboundLabels.colShipmentsDockets)),
          DataColumn(label: Text(OutboundLabels.colPackets)),
        ],
        rows: [
          for (final group in groups) ...[
            DataRow(
              color: WidgetStateProperty.all(
                themes.lightGrayColor.withValues(alpha: 0.5),
              ),
              cells: [
                DataCell(Text('${group.slNo}')),
                DataCell(Text(group.bagLabel)),
                DataCell(Text(group.destHub)),
                DataCell(Text('${group.shipmentCount} Shipments')),
                DataCell(Text('${group.packetCount}')),
              ],
            ),
            for (final shipment in group.shipments)
              DataRow(
                cells: [
                  const DataCell(Text('')),
                  DataCell(
                    Text(
                      '- ${shipment.docketNo} (${shipment.displayCodeSuffix})',
                    ),
                  ),
                  DataCell(Text(shipment.destHubDisplay)),
                  const DataCell(Text('1')),
                  DataCell(Text(shipment.packetsDisplay)),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
