import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/bagging_details_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_copyable.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// Read-only **Bagging Details** — matches admin panel (summary + shipments table).
class BaggingDetailsView extends GetView<BaggingDetailsController> {
  const BaggingDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final branchList = Get.find<OutboundBranchListController>();
    return Obx(() {
      final loading = controller.isLoading.value;
      final printing = controller.isPrinting.value;
      final err = controller.errorMessage.value.trim();
      final detail = controller.detail.value;

      return OutboundScreen(
        title: OutboundLabels.baggingDetailsTitle,
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
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final summary = _BagSummaryPanel(
                  detail: detail,
                  branchLabel: branchList.displayLabelForId,
                  busy: printing,
                  onBack: () => Get.back(),
                  onAddMore:
                      printing ? null : controller.openBaggingToAddMore,
                  onPrint: printing ? null : controller.printChallan,
                );
                final shipments = _IncludedShipmentsPanel(
                  detail: detail,
                  onViewShipment: (item) => _showShipmentSheet(context, item),
                );
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: summary),
                      SizedBox(width: 12.w),
                      Expanded(flex: 6, child: shipments),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    summary,
                    SizedBox(height: 12.h),
                    shipments,
                  ],
                );
              },
            ),
        ],
      );
    });
  }

  void _showShipmentSheet(BuildContext context, BagDetailItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Shipment details',
                style: themes.fontSize18_600.copyWith(fontSize: 15.sp),
              ),
              SizedBox(height: 12.h),
              _ShipmentDetailRow(
                label: OutboundLabels.colShipmentId,
                value: _formatShipmentId(item.shipmentId),
                copyValue: item.shipmentId,
              ),
              _ShipmentDetailRow(
                label: OutboundLabels.colAwb,
                value: item.shipmentInvoiceNo,
                copyable: true,
              ),
              _ShipmentDetailRow(
                label: OutboundLabels.colDestination,
                value: item.destinationCity,
              ),
              _ShipmentDetailRow(
                label: OutboundLabels.colBoxes,
                value: item.noOfPackage ?? '1',
              ),
              _ShipmentDetailRow(
                label: OutboundLabels.colStatus,
                value: item.shipmentStatus,
              ),
              _ShipmentDetailRow(
                label: OutboundLabels.colWeight,
                value: item.totalWeight,
              ),
              if (item.senderName?.trim().isNotEmpty == true)
                _ShipmentDetailRow(
                  label: 'Sender',
                  value: item.senderName,
                ),
              if (item.receiverName?.trim().isNotEmpty == true)
                _ShipmentDetailRow(
                  label: OutboundLabels.receiverName,
                  value: item.receiverName,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BagSummaryPanel extends StatelessWidget {
  const _BagSummaryPanel({
    required this.detail,
    required this.branchLabel,
    required this.busy,
    required this.onBack,
    required this.onAddMore,
    required this.onPrint,
  });

  final BagDetail detail;
  final String Function(String? id) branchLabel;
  final bool busy;
  final VoidCallback onBack;
  final VoidCallback? onAddMore;
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final count = detail.shipmentCountDisplay;
    final origin = _locationLabel(
      apiName: detail.originBranchName,
      id: detail.originBranchId,
      resolveId: branchLabel,
    );
    final destination = _locationLabel(
      apiName: detail.destinationSectorName,
      id: detail.destinationSectorId,
      resolveId: branchLabel,
    );
    final seal = detail.metalSealNo?.trim();
    final bagCode = detail.bagCode?.trim();

    return OutboundAdminSection(
      title: OutboundLabels.sectionBagSummary,
      trailing: bagCode != null && bagCode.isNotEmpty
          ? _HeaderBadge(text: bagCode)
          : null,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${OutboundLabels.totalShipmentsInBag}: $count',
                style: themes.fontSize14_500.copyWith(
                  color: themes.darkCyanBlue,
                  fontSize: 12.sp,
                ),
              ),
            ),
            _StatusBadge(
              open: detail.isOpenForChanges,
              label: detail.manifestStatus,
            ),
          ],
        ),
        SizedBox(height: 4.h),
        _SummaryGrid(
          cells: [
            _SummaryCell(
              label: OutboundLabels.metalSeal.toUpperCase(),
              value: seal != null && seal.isNotEmpty ? seal : '—',
              copyValue: seal,
            ),
            _SummaryCell(label: 'ORIGIN DEPOT', value: origin),
            _SummaryCell(label: 'DESTINATION DEPOT', value: destination),
            _SummaryCell(
              label: OutboundLabels.labelTotalBoxes.toUpperCase(),
              value: '${detail.totalBoxes}',
            ),
            _SummaryCell(
              label: OutboundLabels.totalWeight.toUpperCase(),
              value: detail.totalWeightDisplay,
            ),
            _SummaryCell(
              label: OutboundLabels.labelCreatedBy.toUpperCase(),
              value: detail.createdByDisplay,
            ),
            _SummaryCell(
              label: OutboundLabels.labelDateScanned.toUpperCase(),
              value: _formatScannedDate(detail.createdAt),
              fullWidth: true,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          height: OutboundButtons.height,
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: Icon(Icons.arrow_back, size: 16.sp, color: themes.darkCyanBlue),
            label: Text(OutboundLabels.btnPerformBagging),
            style: OutboundButtons.secondaryStyle(),
          ),
        ),
        SizedBox(height: 8.h),
        OutboundButtonRow(
          start: OutboundSecondaryButton(
            label: OutboundLabels.btnAddMore,
            onPressed: onAddMore,
          ),
          end: OutboundPrimaryButtonCompact(
            title: OutboundLabels.btnPrintChallan,
            onPressed: onPrint,
            isLoading: busy,
          ),
        ),
      ],
    );
  }

  static String _locationLabel({
    String? apiName,
    String? id,
    required String Function(String? id) resolveId,
  }) {
    final name = apiName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (id == null || id.trim().isEmpty) return '—';
    return resolveId(id.trim());
  }

  static String _formatScannedDate(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value.replaceFirst(' ', 'T'));
    if (parsed != null) {
      return DateFormat('dd-MMM-yyyy hh:mm a').format(parsed);
    }
    return value;
  }
}

class _IncludedShipmentsPanel extends StatelessWidget {
  const _IncludedShipmentsPanel({
    required this.detail,
    required this.onViewShipment,
  });

  final BagDetail detail;
  final void Function(BagDetailItem item) onViewShipment;

  @override
  Widget build(BuildContext context) {
    final items = detail.items;
    final count = detail.shipmentCountDisplay;

    return OutboundAdminSection(
      title: OutboundLabels.sectionIncludedShipments,
      trailing: _PurpleBadge(
        text: '$count ${OutboundLabels.shipmentsCountBadge}',
      ),
      children: [
        if (items.isEmpty)
          Text(
            'No shipments in this bag.',
            style: themes.fontSize14_400.copyWith(color: themes.grayColor),
          )
        else
          Card(
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
                showCheckboxColumn: false,
                headingRowHeight: 44,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 64,
                headingTextStyle: themes.fontSize14_500.copyWith(
                  fontSize: 10.sp,
                  color: themes.grayColor,
                ),
                columns: const [
                  DataColumn(label: Text(OutboundLabels.colSlNo)),
                  DataColumn(label: Text('SHIPMENT ID')),
                  DataColumn(label: Text(OutboundLabels.colAwb)),
                  DataColumn(label: Text('DESTINATION')),
                  DataColumn(label: Text(OutboundLabels.colBoxes)),
                  DataColumn(label: Text(OutboundLabels.colStatus)),
                  DataColumn(label: Text(OutboundLabels.colMode)),
                ],
                rows: [
                  for (var i = 0; i < items.length; i++)
                    DataRow(
                      cells: [
                        DataCell(Text('${i + 1}')),
                        DataCell(
                          OutboundCopyableTableCell(
                            value: items[i].shipmentId,
                            displayText: _formatShipmentId(items[i].shipmentId),
                            emphasized: true,
                            snackbarTitle: 'Bagging',
                          ),
                        ),
                        DataCell(
                          OutboundCopyableTableCell(
                            value: items[i].shipmentInvoiceNo,
                            emphasized: true,
                            snackbarTitle: 'Bagging',
                          ),
                        ),
                        DataCell(
                          Text(
                            items[i].destinationCity ?? '—',
                            style: themes.fontSize14_400.copyWith(
                              color: themes.darkCyanBlue,
                            ),
                          ),
                        ),
                        DataCell(Text(items[i].noOfPackage ?? '1')),
                        DataCell(
                          _StatusPill(text: items[i].shipmentStatus ?? '—'),
                        ),
                        DataCell(
                          OutboundTableTextLink(
                            label: OutboundLabels.btnView,
                            onPressed: () => onViewShipment(items[i]),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.cells});

  final List<_SummaryCell> cells;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    var i = 0;
    while (i < cells.length) {
      final cell = cells[i];
      if (cell.fullWidth) {
        rows.add(cell);
        i++;
      } else if (i + 1 < cells.length && !cells[i + 1].fullWidth) {
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cells[i]),
              SizedBox(width: 8.w),
              Expanded(child: cells[i + 1]),
            ],
          ),
        );
        i += 2;
      } else {
        rows.add(cell);
        i++;
      }
      if (i <= cells.length) {
        rows.add(SizedBox(height: 8.h));
      }
    }
    return Column(children: rows);
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    this.copyValue,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final String? copyValue;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: themes.lightGrayColor.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: themes.grayColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: themes.fontSize14_500.copyWith(
              fontSize: 9.sp,
              color: themes.grayColor,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 4.h),
          copyValue?.trim().isNotEmpty == true
              ? OutboundCopyableInline(
                  text: value,
                  value: copyValue,
                  style: themes.fontSize14_500.copyWith(fontSize: 12.sp),
                  snackbarTitle: 'Bagging',
                  compact: true,
                )
              : Text(
                  value,
                  style: themes.fontSize14_500.copyWith(fontSize: 12.sp),
                ),
        ],
      ),
    );
    return box;
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: themes.whiteColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: OutboundCopyableInline(
        text: text,
        style: themes.fontSize14_500.copyWith(
          fontSize: 10.sp,
          color: themes.darkCyanBlue,
        ),
        snackbarTitle: 'Bagging',
        compact: true,
      ),
    );
  }
}

class _PurpleBadge extends StatelessWidget {
  const _PurpleBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF7E57C2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: themes.fontSize14_500.copyWith(
          fontSize: 10.sp,
          color: themes.whiteColor,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.open, this.label});

  final bool open;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final bg = open ? const Color(0xFF2E7D32) : themes.grayColor;
    final text = open
        ? OutboundLabels.openForChanges
        : (label?.trim().isNotEmpty == true
            ? label!.trim()
            : OutboundLabels.bagLocked);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            open ? Icons.lock_open : Icons.lock,
            size: 12.sp,
            color: themes.whiteColor,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: themes.fontSize14_500.copyWith(
              fontSize: 9.sp,
              color: themes.whiteColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: themes.blueGray,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: themes.fontSize14_400.copyWith(
          fontSize: 10.sp,
          color: themes.darkCyanBlue,
        ),
      ),
    );
  }
}

class _ShipmentDetailRow extends StatelessWidget {
  const _ShipmentDetailRow({
    required this.label,
    required this.value,
    this.copyValue,
    this.copyable = false,
  });

  final String label;
  final String? value;
  final String? copyValue;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    final v = value?.trim();
    if (v == null || v.isEmpty) return const SizedBox.shrink();
    final raw = copyValue?.trim().isNotEmpty == true
        ? copyValue!.trim()
        : (copyable ? v : null);
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: themes.fontSize14_500.copyWith(color: themes.grayColor),
            ),
          ),
          Expanded(
            child: raw != null
                ? OutboundCopyableInline(
                    text: v,
                    value: raw,
                    style: themes.fontSize14_400,
                    snackbarTitle: 'Bagging',
                    compact: true,
                  )
                : Text(v, style: themes.fontSize14_400),
          ),
        ],
      ),
    );
  }
}

String _formatShipmentId(String? id) {
  final s = id?.trim();
  if (s == null || s.isEmpty) return '—';
  return s.startsWith('#') ? s : '#$s';
}
