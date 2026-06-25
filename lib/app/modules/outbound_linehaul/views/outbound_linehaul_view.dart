import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_airline_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_airline_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_branch_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_detail_widgets.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_copyable.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_response_panel.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_time_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_transport_mode_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/views/outbound_hub_scan_view.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/outbound_linehaul_controller.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin **Linehaul Booking** — manifest scan, header/destination/booking fields, bag table, submit.
class OutboundLinehaulView extends GetView<OutboundLinehaulController> {
  const OutboundLinehaulView({super.key});

  @override
  Widget build(BuildContext context) {
    final branchList = Get.find<OutboundBranchListController>();
    final airlineList = Get.find<OutboundAirlineListController>();
    return Obx(() {
      final busy = controller.isBusy.value;
      final _ = controller.transportMode.value;
      final __ = controller.bagTableRows.length;
      final ___ = controller.manifestDetail.value;
      final ____ = controller.selectedDestCityId.value;
      final _____ = controller.selectedOriginCityId.value;
      final ______ = controller.selectedAirlineId.value;
      final manifestRevision = controller.manifestLoadRevision.value;
      final airlineLoading = airlineList.isLoadingAirlines.value;
      final airlines = airlineList.airlines.toList(growable: false);

      return OutboundScreen(
        title: OutboundLabels.linehaulScreenTitle,
        busy: busy,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutboundPrimaryButtonCompact(
              title: OutboundLabels.btnShowList,
              onPressed: busy
                  ? null
                  : () => Get.toNamed(Routes.OUTBOUND_LINEHAUL_LIST),
            ),
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionHeaderDetails,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.transportMode,
                required: true,
                child: Obx(
                  () => OutboundTransportModeField(
                    value: controller.transportMode.value,
                    onChanged: controller.onTransportModeChanged,
                  ),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.manifestNo,
                required: true,
                child: OutboundScanField(
                  controller: controller.manifestNoController,
                  focusNode: controller.manifestFocusNode,
                  hintText: OutboundLabels.manifestNo,
                  prefixIcon: const Icon(CupertinoIcons.barcode),
                  onSubmitted: (_) => controller.onManifestSubmitted(),
                  onScanned: controller.onManifestScanned,
                ),
              ),
              OutboundLabeledFieldRow(
                label: controller.transportFieldLabel,
                child: controller.isAirwayMode
                    ? OutboundAirlineSelect(
                        items: airlines,
                        selectedId: airlineList
                            .resolveId(controller.selectedAirlineId.value),
                        isLoading: airlineLoading,
                        dropdownHint: OutboundLabels.airline,
                        onChanged: controller.onAirlineChanged,
                      )
                    : OutboundAdminInput(
                        controller: controller.transportController,
                        hintText: controller.transportFieldLabel,
                      ),
              ),
              OutboundLabeledFieldRow(
                label: controller.mawbVehicleFieldLabel,
                required: true,
                child: OutboundAdminInput(
                  controller: controller.airwayBillController,
                  hintText: controller.mawbVehicleFieldLabel,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.ewayBillNo,
                child: OutboundAdminInput(
                  controller: controller.ewayBillController,
                  hintText: OutboundLabels.ewayBillNo,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.airwayBillDate,
                child: OutboundDateField(
                  key: ValueKey('awb-date-$manifestRevision'),
                  controller: controller.airwayBillDateController,
                  hintText: OutboundLabels.airwayBillDate,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.airwayBillTime,
                child: OutboundTimeField(
                  key: ValueKey('awb-time-$manifestRevision'),
                  controller: controller.airwayBillTimeController,
                  hintText: OutboundLabels.airwayBillTime,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.noOfBags,
                child: OutboundReadOnlyInput(
                  controller: controller.noOfBagsController,
                  hintText: OutboundLabels.noOfBags,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.totalWeight,
                child: OutboundReadOnlyInput(
                  key: ValueKey('total-weight-$manifestRevision'),
                  controller: controller.totalWeightController,
                  hintText: OutboundLabels.totalWeight,
                ),
              ),
              if (controller.manifestDetail.value != null)
                OutboundManifestDetailBody(
                  detail: controller.manifestDetail.value!,
                  compact: true,
                ),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionDestinationDetails,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.cityCode,
                child: Obx(
                  () => OutboundBranchSelect(
                    label: OutboundLabels.cityCode,
                    dropdownHint: OutboundLabels.hintSelectOption,
                    showLabel: false,
                    compact: true,
                    items: branchList.branches,
                    selectedId: controller.selectedDestCityId.value,
                    isLoading: branchList.isLoadingBranches.value,
                    onChanged: controller.onDestCityChanged,
                  ),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.estArrivalDate,
                child: OutboundDateField(
                  controller: controller.estArrivalDateController,
                  hintText: OutboundLabels.estArrivalDate,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.estArrivalTime,
                child: OutboundTimeField(
                  controller: controller.estArrivalTimeController,
                  hintText: OutboundLabels.estArrivalTime,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.totalCdWeight,
                child: OutboundAdminInput(
                  controller: controller.totalCdWeightController,
                  hintText: OutboundLabels.totalCdWeight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.totalBillingWeight,
                child: OutboundAdminInput(
                  controller: controller.totalBillingWeightController,
                  hintText: OutboundLabels.totalBillingWeight,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionBookingDetails,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.flightNo,
                child: OutboundAdminInput(
                  controller: controller.flightNoController,
                  hintText: OutboundLabels.flightNo,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.departureDate,
                child: OutboundDateField(
                  controller: controller.departureDateController,
                  hintText: OutboundLabels.departureDate,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.departureTime,
                child: OutboundTimeField(
                  controller: controller.departureTimeController,
                  hintText: OutboundLabels.departureTime,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.cityCode,
                child: Obx(
                  () => OutboundBranchSelect(
                    label: OutboundLabels.cityCode,
                    dropdownHint: OutboundLabels.hintSelectOption,
                    showLabel: false,
                    compact: true,
                    items: branchList.branches,
                    selectedId: controller.selectedOriginCityId.value,
                    isLoading: branchList.isLoadingBranches.value,
                    onChanged: controller.onOriginCityChanged,
                  ),
                ),
              ),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionBagDetails,
            children: [
              _LinehaulBagTable(rows: controller.bagTableRows),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 200.w,
              child: OutboundPrimaryButtonCompact(
                title: OutboundLabels.btnSubmit,
                onPressed: busy ? null : controller.submitLinehaulBooking,
              ),
            ),
          ),
          // Linehaul report UI — disabled for now.
          // OutboundExpandableSection(
          //   title: OutboundLabels.linehaulReportTitle,
          //   subtitle: OutboundLabels.subtitleLinehaulReport,
          //   initiallyExpanded: false,
          //   children: [
          //     OutboundDateField(
          //       controller: controller.reportStartController,
          //       hintText: OutboundLabels.reportStart,
          //     ),
          //     OutboundDateField(
          //       controller: controller.reportEndController,
          //       hintText: OutboundLabels.reportEnd,
          //     ),
          //     OutboundPrimaryButton(
          //       title: OutboundLabels.btnLinehaulReport,
          //       onPressed: busy ? null : controller.linehaulReport,
          //     ),
          //   ],
          // ),
          if (controller.lastResponseText.value.trim().isNotEmpty)
            OutboundResponsePanel(
              title: 'Message',
              text: controller.lastResponseText.value,
            ),
        ],
      );
    });
  }
}

class _LinehaulBagTable extends StatelessWidget {
  const _LinehaulBagTable({required this.rows});

  final List<LinehaulBagTableRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const OutboundDynamicMapTablePlaceholder();
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
          dataRowMinHeight: 44,
          headingTextStyle: themes.fontSize14_500.copyWith(
            fontSize: 11.sp,
            color: themes.grayColor,
          ),
          columns: const [
            DataColumn(label: Text(OutboundLabels.mBagNumber)),
            DataColumn(label: Text(OutboundLabels.mBagWeight)),
          ],
          rows: rows
              .map(
                (e) => DataRow(
                  cells: [
                    DataCell(
                      OutboundCopyableTableCell(
                        value: e.bagNumber,
                        emphasized: true,
                        snackbarTitle: 'Linehaul',
                      ),
                    ),
                    DataCell(Text(e.weight)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
