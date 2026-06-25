import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_copyable.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/outbound_sector_pickup_controller.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin **Sector Pickup List** — `getpickuplist`, Report + Scan actions.
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

      return OutboundScreen(
        title: OutboundLabels.sectorPickupListTitle,
        busy: false,
        onRefresh: loading
            ? null
            : () async {
                await controller.loadPickupList();
              },
        children: [
          OutboundButtonRow(
            start: OutboundSecondaryButton(
              label: OutboundLabels.btnSectorPickupStatusReport,
              onPressed: busy
                  ? null
                  : () => Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP_STATUS_REPORT),
            ),
            end: OutboundPrimaryButtonCompact(
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
                  onReport: _openReport,
                  onScan: _openPickup,
                ),
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

  void _openReport(SectorPickupRow row) {
    final id = row.id?.trim();
    if (id == null || id.isEmpty) {
      Get.snackbar('Sector pickup', 'Pickup id is missing for this row.',
          duration: const Duration(seconds: 3));
      return;
    }
    Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP_REPORT_SHOW, arguments: id);
  }
}

class _SectorPickupListTable extends StatelessWidget {
  const _SectorPickupListTable({
    required this.rows,
    required this.busy,
    required this.onReport,
    required this.onScan,
  });

  final List<SectorPickupRow> rows;
  final bool busy;
  final void Function(SectorPickupRow row) onReport;
  final void Function(SectorPickupRow row) onScan;

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
            DataColumn(label: Text('ID')),
            DataColumn(label: Text(OutboundLabels.mawbNo)),
            DataColumn(label: Text(OutboundLabels.colHubBranch)),
            DataColumn(label: Text(OutboundLabels.pickupDate)),
            DataColumn(label: Text(OutboundLabels.pickedBy)),
            DataColumn(label: Text(OutboundLabels.colActions)),
          ],
          rows: rows
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(
                      OutboundCopyableTableCell(
                        value: e.id,
                        snackbarTitle: 'Sector pickup',
                      ),
                    ),
                    DataCell(
                      OutboundCopyableTableCell(
                        value: e.mawbNo,
                        emphasized: true,
                        snackbarTitle: 'Sector pickup',
                      ),
                    ),
                    DataCell(Text(_cell(e.displayOriginHub))),
                    DataCell(Text(_pickupDateTime(e))),
                    DataCell(Text(_cell(e.pickedBy))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutboundTableTextLink(
                            label: OutboundLabels.btnReport,
                            onPressed: busy ? null : () => onReport(e),
                          ),
                          SizedBox(width: 8.w),
                          OutboundTableTextLink(
                            label: OutboundLabels.btnScan,
                            onPressed: busy ? null : () => onScan(e),
                          ),
                        ],
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

  static String _pickupDateTime(SectorPickupRow row) {
    final date = row.pickupDate?.trim();
    if (date == null || date.isEmpty) return '—';
    final time = row.pickupTime?.trim();
    if (time == null || time.isEmpty) return date;
    return '$date $time';
  }
}
