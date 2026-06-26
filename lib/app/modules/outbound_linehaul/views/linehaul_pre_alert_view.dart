import 'package:axlpl_delivery/app/data/models/outbound/linehaul_consignment_summary_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_copyable.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/linehaul_pre_alert_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Admin **Linehaul Pre-Alert View** — pre-alert summary, consignment + docket tables, PDF print.
class LinehaulPreAlertView extends GetView<LinehaulPreAlertController> {
  const LinehaulPreAlertView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final printing = controller.isPrinting.value;
      final err = controller.errorMessage.value.trim();
      final detail = controller.detail.value;
      final shipments = controller.shipments.toList(growable: false);
      final consignments = controller.consignmentRows;

      return OutboundScreen(
        title: OutboundLabels.linehaulPreAlertTitle,
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
                  title: OutboundLabels.sectionPreAlertDetails,
                  children: [
                    _PreAlertDetailsTable(
                      detail: detail,
                      controller: controller,
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                OutboundAdminSection(
                  title: OutboundLabels.sectionConsignmentDetails,
                  children: [
                    _ConsignmentTable(rows: consignments),
                    if (shipments.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      _DocketTable(shipments: shipments),
                    ],
                  ],
                ),
                SizedBox(height: 16.h),
                OutboundButtonRow(
                  start: OutboundSecondaryButton(
                    label: OutboundLabels.btnShowList,
                    onPressed: printing ? null : () => Get.back(),
                  ),
                  end: OutboundPrimaryButtonCompact(
                    title: OutboundLabels.btnPrintPreAlert,
                    onPressed: printing ? null : controller.printPreAlert,
                    isLoading: printing,
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }
}

class _PreAlertDetailsTable extends StatelessWidget {
  const _PreAlertDetailsTable({
    required this.detail,
    required this.controller,
  });

  final LinehaulDetail detail;
  final LinehaulPreAlertController controller;

  @override
  Widget build(BuildContext context) {
    final rows = [
      [
        _Pair(OutboundLabels.colOriginHub, controller.originHubLabel()),
        _Pair(OutboundLabels.colDestinationHub, controller.destinationHubLabel()),
        _Pair(
          OutboundLabels.colMawbNo,
          detail.mawbNo ?? detail.airwayBillNo ?? '—',
          copyValue: detail.mawbNo ?? detail.airwayBillNo,
        ),
      ],
      [
        _Pair(OutboundLabels.colFlightNoMode, detail.flightNoAndMode),
        _Pair(OutboundLabels.colFlightDate, controller.flightDateLabel()),
        _Pair(OutboundLabels.colVendor, controller.vendorLabel()),
      ],
      [
        _Pair(OutboundLabels.colStd, _formatStd(detail.stdFromDeparture)),
        _Pair(OutboundLabels.colSta, _formatSta(detail.arrivalTime)),
        _Pair(OutboundLabels.noOfBags, detail.noOfBags ?? detail.noOfBoxes ?? '—'),
      ],
      [
        _Pair(OutboundLabels.colTotalNoOfCons, '${detail.totalConsignments}'),
        _Pair(OutboundLabels.colTotalNoOfBoxes, detail.noOfBoxes ?? '—'),
        _Pair(
          OutboundLabels.colTotalWtInKg,
          _formatWeight(detail.totalWeight),
        ),
      ],
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 320.w),
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.r),
            side: BorderSide(color: themes.grayColor.withValues(alpha: 0.25)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            border: TableBorder.all(
              color: themes.grayColor.withValues(alpha: 0.22),
              width: 0.8,
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              for (var i = 0; i < 6; i++)
                i: FixedColumnWidth(i.isEven ? 92.w : 108.w),
            },
            children: [
              for (final row in rows)
                TableRow(
                  children: [
                    for (final cell in row) ...[
                      _labelCell(cell.label),
                      _valueCell(cell),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _labelCell(String label) {
    return Container(
      color: themes.lightGrayColor.withValues(alpha: 0.35),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: Text(
        label,
        style: themes.fontSize14_500.copyWith(
          fontSize: 10.sp,
          color: themes.grayColor,
        ),
      ),
    );
  }

  static Widget _valueCell(_Pair pair) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      child: pair.copyValue?.trim().isNotEmpty == true
          ? OutboundCopyableInline(
              text: pair.value,
              value: pair.copyValue,
              style: themes.fontSize14_500.copyWith(fontSize: 11.sp),
              snackbarTitle: 'Linehaul',
            )
          : Text(
              pair.value,
              style: themes.fontSize14_500.copyWith(fontSize: 11.sp),
            ),
    );
  }

  static String _formatStd(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return '—';
    final parts = value.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return value;
  }

  static String _formatSta(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (parsed != null) {
      return DateFormat('yyyy-MM-dd HH:mm').format(parsed);
    }
    return value;
  }

  static String _formatWeight(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return '—';
    final numeric = double.tryParse(value.replaceAll(',', ''));
    if (numeric == null) return value;
    final parts = numeric.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$whole.${parts[1]}';
  }
}

class _Pair {
  const _Pair(this.label, this.value, {this.copyValue});
  final String label;
  final String value;
  final String? copyValue;
}

class _ConsignmentTable extends StatelessWidget {
  const _ConsignmentTable({required this.rows});

  final List<LinehaulConsignmentSummary> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No consignment rows.',
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: themes.grayColor.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 10.sp,
            color: themes.whiteColor,
          ),
          headingRowColor: WidgetStateProperty.all(themes.darkCyanBlue),
          columns: const [
            DataColumn(label: Text(OutboundLabels.colSlNo)),
            DataColumn(label: Text(OutboundLabels.colMasterBag)),
            DataColumn(label: Text(OutboundLabels.colBagNo)),
            DataColumn(label: Text(OutboundLabels.colEntryNo)),
            DataColumn(label: Text(OutboundLabels.colDestHub)),
            DataColumn(label: Text(OutboundLabels.colNoOfConsign)),
            DataColumn(label: Text(OutboundLabels.colNoOfBoxes)),
            DataColumn(label: Text(OutboundLabels.colProductMode)),
            DataColumn(label: Text(OutboundLabels.colWeight)),
            DataColumn(label: Text(OutboundLabels.colShipmentType)),
          ],
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text('${row.slNo}')),
                    DataCell(
                      OutboundCopyableTableCell(
                        value: row.masterBag,
                        snackbarTitle: 'Linehaul',
                      ),
                    ),
                    DataCell(
                      OutboundCopyableTableCell(
                        value: row.bagNo,
                        emphasized: true,
                        snackbarTitle: 'Bag',
                      ),
                    ),
                    DataCell(Text(row.entryNo ?? '—')),
                    DataCell(Text(row.destHub ?? '—')),
                    DataCell(Text('${row.consignmentCount}')),
                    DataCell(Text('${row.boxCount}')),
                    DataCell(Text(row.productMode ?? '—')),
                    DataCell(Text(row.weight ?? '—')),
                    DataCell(Text(row.shipmentType ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DocketTable extends StatelessWidget {
  const _DocketTable({required this.shipments});

  final List<ManifestShipmentRef> shipments;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return Text(
        'No docket rows.',
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
        side: BorderSide(color: themes.grayColor.withValues(alpha: 0.2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: DataTable(
          headingRowHeight: 44,
          dataRowMinHeight: 52,
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 10.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text(OutboundLabels.colDocketNo)),
            DataColumn(label: Text(OutboundLabels.colSender)),
            DataColumn(label: Text(OutboundLabels.colReceiver)),
            DataColumn(label: Text(OutboundLabels.colPcs)),
            DataColumn(label: Text(OutboundLabels.colNetWeight)),
            DataColumn(label: Text(OutboundLabels.colGrossWeight)),
            DataColumn(label: Text(OutboundLabels.colPaid)),
          ],
          rows: shipments
              .map(
                (shipment) => DataRow(
                  cells: [
                    DataCell(
                      OutboundCopyableTableCell(
                        value: shipment.docketNo,
                        emphasized: true,
                        snackbarTitle: 'Docket',
                      ),
                    ),
                    DataCell(
                      _WrappedTableText(shipment.senderName),
                    ),
                    DataCell(
                      _WrappedTableText(shipment.receiverName),
                    ),
                    DataCell(Text(shipment.pcsDisplay)),
                    DataCell(Text(shipment.netWeightDisplay)),
                    DataCell(Text(shipment.grossWeightDisplay)),
                    DataCell(Text(shipment.paidDisplay)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _WrappedTableText extends StatelessWidget {
  const _WrappedTableText(this.text);

  final String? text;

  @override
  Widget build(BuildContext context) {
    final value = text?.trim();
    return Text(
      value == null || value.isEmpty ? '—' : value,
      softWrap: true,
      style: themes.fontSize14_400.copyWith(fontSize: 10.sp),
    );
  }
}
