import 'package:axlpl_delivery/app/data/models/outbound/linehaul_consignment_summary_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_copyable.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/linehaul_pre_alert_controller.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
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
              mainAxisSize: MainAxisSize.min,
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
              mainAxisSize: MainAxisSize.min,
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
                OutboundAdminSection(
                  title: OutboundLabels.sectionConsignmentDetails,
                  children: [
                    _ConsignmentTable(rows: consignments),
                  ],
                ),
                OutboundAdminSection(
                  title: OutboundLabels.sectionLinehaulPreAlertDocket,
                  children: [
                    _DocketTable(shipments: shipments),
                  ],
                ),
                _PreAlertActionButtons(
                  printing: printing,
                  onPrint: controller.printPreAlert,
                  onBackToList: _backToLinehaulList,
                ),
              ],
            ),
        ],
      );
    });
  }

  static void _backToLinehaulList() {
    if (Get.key.currentState?.canPop() == true) {
      Get.back();
      return;
    }
    Get.offNamed(Routes.OUTBOUND_LINEHAUL_LIST);
  }
}

class _PreAlertActionButtons extends StatelessWidget {
  const _PreAlertActionButtons({
    required this.printing,
    required this.onPrint,
    required this.onBackToList,
  });

  final bool printing;
  final Future<void> Function() onPrint;
  final VoidCallback onBackToList;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutboundPrimaryButton(
          title: OutboundLabels.btnPrintPreAlert,
          onPressed: printing ? null : onPrint,
          isLoading: printing,
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          height: OutboundButtons.height,
          child: OutlinedButton.icon(
            onPressed: printing ? null : onBackToList,
            icon: Icon(
              Icons.arrow_back,
              size: 16.sp,
              color: printing ? themes.grayColor : themes.darkCyanBlue,
            ),
            label: Text(OutboundLabels.btnBackToList),
            style: OutboundButtons.secondaryStyle(enabled: !printing),
          ),
        ),
      ],
    );
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
    final cells = [
      _Pair(OutboundLabels.colOriginHub, controller.originHubLabel()),
      _Pair(OutboundLabels.colDestinationHub, controller.destinationHubLabel()),
      _Pair(
        OutboundLabels.colMawbNo,
        detail.mawbNo ?? detail.airwayBillNo ?? '—',
        copyValue: detail.mawbNo ?? detail.airwayBillNo,
      ),
      _Pair(OutboundLabels.colFlightNoMode, detail.flightNoAndMode),
      _Pair(OutboundLabels.colFlightDate, controller.flightDateLabel()),
      _Pair(OutboundLabels.colVendor, controller.vendorLabel()),
      _Pair(OutboundLabels.colStd, _formatStd(detail.stdFromDeparture)),
      _Pair(OutboundLabels.colSta, _formatSta(detail.arrivalTime)),
      _Pair(OutboundLabels.noOfBags, detail.noOfBags ?? detail.noOfBoxes ?? '—'),
      _Pair(OutboundLabels.colTotalNoOfCons, '${detail.totalConsignments}'),
      _Pair(OutboundLabels.colTotalNoOfBoxes, detail.noOfBoxes ?? '—'),
      _Pair(
        OutboundLabels.colTotalWtInKg,
        _formatWeight(detail.totalWeight),
      ),
    ];

    return _PreAlertDetailsMobileList(rows: cells);
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

class _PreAlertDetailsMobileList extends StatelessWidget {
  const _PreAlertDetailsMobileList({required this.rows});

  final List<_Pair> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.r),
        side: BorderSide(color: themes.grayColor.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.8,
                color: themes.grayColor.withValues(alpha: 0.22),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 118.w,
                    child: Text(
                      rows[i].label,
                      style: themes.fontSize14_500.copyWith(
                        fontSize: 10.sp,
                        color: themes.grayColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: rows[i].copyValue?.trim().isNotEmpty == true
                        ? OutboundCopyableInline(
                            text: rows[i].value,
                            value: rows[i].copyValue,
                            style: themes.fontSize14_500.copyWith(fontSize: 11.sp),
                            snackbarTitle: 'Linehaul',
                          )
                        : Text(
                            rows[i].value,
                            style: themes.fontSize14_500.copyWith(fontSize: 11.sp),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) SizedBox(height: 8.h),
          _PreAlertRecordCard(
            fields: [
              _Field(OutboundLabels.colSlNo, '${rows[i].slNo}'),
              _Field(OutboundLabels.colMasterBag, rows[i].masterBag ?? '—'),
              _Field(OutboundLabels.colBagNo, rows[i].bagNo ?? '—', copyable: true, copyValue: rows[i].bagNo),
              _Field(OutboundLabels.colEntryNo, rows[i].entryNo ?? '—'),
              _Field(OutboundLabels.colDestHub, rows[i].destHub ?? '—'),
              _Field(OutboundLabels.colNoOfConsign, '${rows[i].consignmentCount}'),
              _Field(OutboundLabels.colNoOfBoxes, '${rows[i].boxCount}'),
              _Field(OutboundLabels.colProductMode, rows[i].productMode ?? '—'),
              _Field(OutboundLabels.colWeight, rows[i].weight ?? '—'),
              _Field(OutboundLabels.colShipmentType, rows[i].shipmentType ?? '—'),
            ],
          ),
        ],
      ],
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shipments.length; i++) ...[
          if (i > 0) SizedBox(height: 8.h),
          _PreAlertRecordCard(
            fields: [
              _Field(
                OutboundLabels.colDocketNo,
                shipments[i].docketNo,
                copyable: true,
                copyValue: shipments[i].id ?? shipments[i].shipmentInvoiceNo,
              ),
              _Field(OutboundLabels.colSender, shipments[i].senderName ?? '—'),
              _Field(OutboundLabels.colReceiver, shipments[i].receiverName ?? '—'),
              _Field(OutboundLabels.colPcs, shipments[i].pcsDisplay),
              _Field(OutboundLabels.colNetWeight, shipments[i].netWeightDisplay),
              _Field(OutboundLabels.colGrossWeight, shipments[i].grossWeightDisplay),
              _Field(OutboundLabels.colPaid, shipments[i].paidDisplay),
            ],
          ),
        ],
      ],
    );
  }
}

class _Field {
  const _Field(
    this.label,
    this.value, {
    this.copyable = false,
    this.copyValue,
  });

  final String label;
  final String value;
  final bool copyable;
  final String? copyValue;
}

class _PreAlertRecordCard extends StatelessWidget {
  const _PreAlertRecordCard({required this.fields});

  final List<_Field> fields;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.r),
        side: BorderSide(color: themes.grayColor.withValues(alpha: 0.22)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < fields.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 0.8,
                color: themes.grayColor.withValues(alpha: 0.18),
              ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 108.w,
                    child: Text(
                      fields[i].label,
                      style: themes.fontSize14_500.copyWith(
                        fontSize: 10.sp,
                        color: themes.grayColor,
                      ),
                    ),
                  ),
                  Expanded(
                    child: fields[i].copyable &&
                            fields[i].copyValue?.trim().isNotEmpty == true
                        ? OutboundCopyableInline(
                            text: fields[i].value,
                            value: fields[i].copyValue,
                            style: themes.fontSize14_400.copyWith(fontSize: 11.sp),
                            snackbarTitle: 'Linehaul',
                            compact: true,
                          )
                        : Text(
                            fields[i].value,
                            style: themes.fontSize14_400.copyWith(fontSize: 11.sp),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
