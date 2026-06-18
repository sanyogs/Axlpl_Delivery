import 'package:axlpl_delivery/app/data/models/outbound/pickup_report_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/outbound_sector_pickup_controller.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin **Sector Pickup List** — `getpickuplist`, tap row to open scan screen.
class SectorPickupListView extends StatefulWidget {
  const SectorPickupListView({super.key});

  @override
  State<SectorPickupListView> createState() => _SectorPickupListViewState();
}

class _SectorPickupListViewState extends State<SectorPickupListView> {
  late final OutboundSectorPickupController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OutboundSectorPickupController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadPickupList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isListLoading.value;
      final busy = controller.isBusy.value;
      final rows = controller.pickupRows;
      final _ = controller.pickupReportRows.length;

      return OutboundScreen(
        title: OutboundLabels.sectorPickupListTitle,
        busy: false,
        onRefresh: loading
            ? null
            : () async {
                await controller.loadPickupList();
              },
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnNewSectorPickup,
              onPressed: busy ? null : _openNewPickup,
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectorPickupListTitle,
            trailing: TextButton.icon(
              onPressed: busy ? null : _openNewPickup,
              style: TextButton.styleFrom(
                backgroundColor: themes.whiteColor,
                foregroundColor: themes.darkCyanBlue,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(Icons.add, size: 16.sp, color: themes.darkCyanBlue),
              label: Text(
                OutboundLabels.btnNewSectorPickup,
                style: themes.fontSize14_500.copyWith(
                  fontSize: 11.sp,
                  color: themes.darkCyanBlue,
                ),
              ),
            ),
            children: [
              Text(
                OutboundLabels.subtitleSectorPickupList,
                style: themes.fontSize14_400.copyWith(color: themes.grayColor),
              ),
              if (loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: themes.darkCyanBlue),
                  ),
                )
              else if (rows.isEmpty)
                Text(
                  OutboundLabels.sectorPickupListEmpty,
                  style:
                      themes.fontSize14_400.copyWith(color: themes.grayColor),
                )
              else
                _SectorPickupListTable(
                  rows: rows,
                  busy: busy,
                  onRowTap: _openPickup,
                ),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectorPickupReportTitle,
            children: [
              Text(
                OutboundLabels.subtitleSectorPickupReport,
                style: themes.fontSize14_400.copyWith(color: themes.grayColor),
              ),
              OutboundDateField(
                controller: controller.reportStartController,
                hintText: OutboundLabels.reportStart,
              ),
              OutboundDateField(
                controller: controller.reportEndController,
                hintText: OutboundLabels.reportEnd,
              ),
              OutboundPrimaryButton(
                title: OutboundLabels.btnPickupReport,
                onPressed: busy ? null : controller.pickupReport,
              ),
              _PickupReportTable(rows: controller.pickupReportRows),
            ],
          ),
        ],
      );
    });
  }

  void _openNewPickup() {
    Get.snackbar(
      'Sector pickup',
      'Pickups are created when linehaul arrives. Select an existing row from the list, or scan MAWB after opening one.',
      duration: const Duration(seconds: 4),
    );
    controller.resetSession();
    Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP);
  }

  void _openPickup(SectorPickupRow row) {
    controller.resetSession();
    Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP, arguments: row);
  }
}

class _SectorPickupListTable extends StatelessWidget {
  const _SectorPickupListTable({
    required this.rows,
    required this.busy,
    required this.onRowTap,
  });

  final List<SectorPickupRow> rows;
  final bool busy;
  final void Function(SectorPickupRow row) onRowTap;

  @override
  Widget build(BuildContext context) {
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
        child: DataTable(
          headingRowHeight: 40,
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 11.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text('Pickup id')),
            DataColumn(label: Text(OutboundLabels.mawbNo)),
            DataColumn(label: Text(OutboundLabels.colOriginHub)),
            DataColumn(label: Text(OutboundLabels.colDestinationHub)),
            DataColumn(label: Text(OutboundLabels.flightNo)),
            DataColumn(label: Text(OutboundLabels.pickupDate)),
            DataColumn(label: Text(OutboundLabels.pickupTime)),
            DataColumn(label: Text(OutboundLabels.pickedBy)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: rows
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(Text(_cell(e.id))),
                    DataCell(Text(_cell(e.mawbNo))),
                    DataCell(Text(_cell(e.displayOriginHub))),
                    DataCell(Text(_cell(e.displayDestHub))),
                    DataCell(Text(_cell(e.flightNo))),
                    DataCell(Text(_cell(e.pickupDate))),
                    DataCell(Text(_cell(e.pickupTime))),
                    DataCell(Text(_cell(e.pickedBy))),
                    DataCell(
                      TextButton(
                        onPressed: busy ? null : () => onRowTap(e),
                        child: const Text('Open'),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  static String _cell(String? v) {
    final t = v?.trim();
    if (t == null || t.isEmpty) return '—';
    return t;
  }
}

class _PickupReportTable extends StatelessWidget {
  const _PickupReportTable({required this.rows});

  final List<PickupReportRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No report rows — generate report above.',
        style: themes.fontSize14_400.copyWith(color: themes.grayColor),
      );
    }
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: DataTable(
        columns: const [
          DataColumn(label: Text(OutboundLabels.colStatus)),
          DataColumn(label: Text('Count')),
        ],
        rows: rows
            .map(
              (e) => DataRow(
                cells: [
                  DataCell(Text(_SectorPickupListTable._cell(e.status))),
                  DataCell(Text(_SectorPickupListTable._cell(e.count))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
