import 'package:axlpl_delivery/app/modules/outbound_common/outbound_airline_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_airline_select.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_date_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_response_panel.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_screen.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_time_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_transport_mode_field.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/linehaul_edit_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Admin linehaul edit — maps to `editlinehaul` POST.
class LinehaulEditView extends GetView<LinehaulEditController> {
  const LinehaulEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final airlineList = Get.find<OutboundAirlineListController>();
    return Obx(() {
      final busy = controller.isBusy.value;
      final loading = controller.isLoading.value;
      final _ = controller.transportMode.value;
      final __ = controller.selectedAirlineId.value;
      final airlineLoading = airlineList.isLoadingAirlines.value;
      final airlines = airlineList.airlines.toList(growable: false);

      return OutboundScreen(
        title: OutboundLabels.linehaulEditTitle,
        busy: busy,
        children: [
          if (loading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: CircularProgressIndicator(color: themes.darkCyanBlue),
              ),
            ),
          OutboundAdminSection(
            title: OutboundLabels.sectionHeaderDetails,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.linehaulId,
                child: OutboundReadOnlyInput(
                  controller: controller.linehaulIdController,
                  hintText: OutboundLabels.linehaulId,
                  copyable: true,
                  snackbarTitle: 'Linehaul',
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.transportMode,
                child: OutboundTransportModeField(
                  value: controller.transportMode.value,
                  onChanged: controller.onTransportModeChanged,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.colMawbVehicle,
                child: OutboundAdminInput(
                  controller: controller.vehicleNoController,
                  hintText: OutboundLabels.colMawbVehicle,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.airwayBillNo,
                child: OutboundAdminInput(
                  controller: controller.mawbNoController,
                  hintText: OutboundLabels.airwayBillNo,
                ),
              ),
              OutboundLabeledFieldRow(
                label: 'Trip No',
                child: OutboundAdminInput(
                  controller: controller.tripNoController,
                  hintText: 'Trip No',
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.airline,
                child: OutboundAirlineSelect(
                  items: airlines,
                  selectedId:
                      airlineList.resolveId(controller.selectedAirlineId.value),
                  isLoading: airlineLoading,
                  dropdownHint: OutboundLabels.airline,
                  onChanged: controller.onAirlineChanged,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.flightNo,
                child: OutboundAdminInput(
                  controller: controller.flightNoController,
                  hintText: OutboundLabels.flightNo,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.ewayBillNo,
                child: OutboundAdminInput(
                  controller: controller.ewayBillController,
                  hintText: OutboundLabels.ewayBillNo,
                ),
              ),
            ],
          ),
          OutboundAdminSection(
            title: OutboundLabels.sectionBookingDetails,
            children: [
              OutboundLabeledFieldRow(
                label: OutboundLabels.transport,
                child: OutboundAdminInput(
                  controller: controller.driverNameController,
                  hintText: OutboundLabels.transport,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.driverMobile,
                child: OutboundAdminInput(
                  controller: controller.driverMobileController,
                  hintText: OutboundLabels.driverMobile,
                  keyboardType: TextInputType.phone,
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
                label: OutboundLabels.estArrivalDate,
                child: OutboundDateField(
                  controller: controller.arrivalDateController,
                  hintText: OutboundLabels.estArrivalDate,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.estArrivalTime,
                child: OutboundTimeField(
                  controller: controller.arrivalTimeController,
                  hintText: OutboundLabels.estArrivalTime,
                ),
              ),
              OutboundLabeledFieldRow(
                label: OutboundLabels.remarks,
                child: OutboundAdminInput(
                  controller: controller.remarksController,
                  hintText: OutboundLabels.remarks,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutboundSecondaryButton(
                  label: OutboundLabels.btnDelete,
                  onPressed: busy ? null : controller.confirmDelete,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: OutboundPrimaryButton(
                  title: OutboundLabels.btnSaveChanges,
                  onPressed: busy ? null : controller.submitEdit,
                ),
              ),
            ],
          ),
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
