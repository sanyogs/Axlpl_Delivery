import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_airline_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/common_widget/common_tow_btn_dialog.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Edit form for `editlinehaul` / `deletelinehaul` (admin list actions).
class LinehaulEditController extends GetxController {
  LinehaulEditController({
    OutboundRepository? repo,
  }) : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final isLoading = false.obs;
  final lastResponseText = ''.obs;
  final transportMode = OutboundLabels.modeAirway.obs;
  final selectedAirlineId = RxnString();

  late final OutboundLinehaulRow _row;

  final linehaulIdController = TextEditingController();
  final vehicleNoController = TextEditingController();
  final driverNameController = TextEditingController();
  final driverMobileController = TextEditingController();
  final mawbNoController = TextEditingController();
  final tripNoController = TextEditingController();
  final departureDateController = TextEditingController();
  final departureTimeController = TextEditingController();
  final arrivalDateController = TextEditingController();
  final arrivalTimeController = TextEditingController();
  final remarksController = TextEditingController();
  final flightNoController = TextEditingController();
  final airlineController = TextEditingController();
  final ewayBillController = TextEditingController();

  String get linehaulId => _row.linehaulId?.trim() ?? '';

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is! OutboundLinehaulRow) {
      Get.back();
      return;
    }
    _row = args;
    linehaulIdController.text = linehaulId;
    _prefillFromRow(_row);
    _loadDetail();
  }

  @override
  void onClose() {
    linehaulIdController.dispose();
    vehicleNoController.dispose();
    driverNameController.dispose();
    driverMobileController.dispose();
    mawbNoController.dispose();
    tripNoController.dispose();
    departureDateController.dispose();
    departureTimeController.dispose();
    arrivalDateController.dispose();
    arrivalTimeController.dispose();
    remarksController.dispose();
    flightNoController.dispose();
    airlineController.dispose();
    ewayBillController.dispose();
    super.onClose();
  }

  void onTransportModeChanged(String mode) {
    transportMode.value = mode;
    if (mode != OutboundLabels.modeAirway) {
      selectedAirlineId.value = null;
    } else {
      selectedAirlineId.value = _resolveAirlineId(airlineController.text);
    }
  }

  void onAirlineChanged(String? id) {
    final resolved = _resolveAirlineId(id);
    selectedAirlineId.value = resolved;
    airlineController.text = resolved ?? '';
  }

  Future<void> _loadDetail() async {
    final lookup = _row.detailLookupRef ?? linehaulId;
    if (lookup.isEmpty) return;

    isLoading.value = true;
    try {
      final detail = await _repo.linehaulDetails(lookup);
      if (detail != null) _prefillFromDetail(detail);
    } finally {
      isLoading.value = false;
    }
  }

  void _prefillFromRow(OutboundLinehaulRow row) {
    _setIfEmpty(vehicleNoController, row.vehicleNo);
    _setIfEmpty(driverNameController, row.driverName);
    _setIfEmpty(mawbNoController, row.mawbNo);
    _setIfEmpty(tripNoController, row.tripNo);
    if (row.transportType != null && row.transportType!.trim().isNotEmpty) {
      transportMode.value = row.transportType!.trim();
    }
  }

  void _prefillFromDetail(LinehaulDetail detail) {
    _setIfEmpty(linehaulIdController, detail.linehaulId);
    _setIfEmpty(vehicleNoController, detail.vehicleNo);
    _setIfEmpty(driverNameController, detail.driverName);
    _setIfEmpty(driverMobileController, detail.driverMobile);
    _setIfEmpty(
      mawbNoController,
      detail.mawbNo ?? detail.airwayBillNo,
    );
    _setIfEmpty(tripNoController, detail.tripNo);
    _setIfEmpty(flightNoController, detail.flightNo);
    _setAirlineValue(detail.airline);
    _setIfEmpty(ewayBillController, detail.ewayBill);
    _setIfEmpty(remarksController, detail.remarks);
    _splitDateTime(
        detail.departureTime, departureDateController, departureTimeController);
    _splitDateTime(
        detail.arrivalTime, arrivalDateController, arrivalTimeController);
    if (detail.transportType != null &&
        detail.transportType!.trim().isNotEmpty) {
      transportMode.value = detail.transportType!.trim();
    }
  }

  static void _setIfEmpty(TextEditingController c, String? value) {
    if (c.text.trim().isNotEmpty) return;
    final t = value?.trim();
    if (t != null && t.isNotEmpty) c.text = t;
  }

  void _setAirlineValue(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return;
    if (airlineController.text.trim().isEmpty) {
      airlineController.text = t;
    }
    selectedAirlineId.value = _resolveAirlineId(t);
  }

  String? _resolveAirlineId(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (Get.isRegistered<OutboundAirlineListController>()) {
      return Get.find<OutboundAirlineListController>().resolveId(raw);
    }
    return raw;
  }

  String _airlineForApi() {
    final selected = selectedAirlineId.value?.trim();
    if (transportMode.value == OutboundLabels.modeAirway &&
        selected != null &&
        selected.isNotEmpty) {
      return _resolveAirlineId(selected) ?? selected;
    }
    final raw = airlineController.text.trim();
    return _resolveAirlineId(raw) ?? raw;
  }

  static void _splitDateTime(
    String? raw,
    TextEditingController date,
    TextEditingController time,
  ) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return;
    final parts = t.split(' ');
    if (date.text.trim().isEmpty && parts.isNotEmpty) date.text = parts[0];
    if (time.text.trim().isEmpty && parts.length > 1) {
      final hm = parts[1];
      time.text = hm.length >= 5 ? hm.substring(0, 5) : hm;
    }
  }

  Future<void> submitEdit() async {
    final id = linehaulIdController.text.trim();
    if (id.isEmpty) {
      Get.snackbar('Linehaul', 'Linehaul id is required');
      return;
    }

    isBusy.value = true;
    try {
      final r = await _repo.editLinehaul(
        linehaulId: id,
        vehicleNo: vehicleNoController.text,
        driverName: driverNameController.text,
        driverMobile: driverMobileController.text,
        mawbNo: mawbNoController.text,
        tripNo: tripNoController.text,
        departureTime: OutboundApiParams.combineDateTime(
          departureDateController.text,
          departureTimeController.text,
        ),
        arrivalTime: OutboundApiParams.combineDateTime(
          arrivalDateController.text,
          arrivalTimeController.text,
        ),
        remarks: remarksController.text,
        flightNo: flightNoController.text,
        airline: _airlineForApi(),
        ewayBill: ewayBillController.text,
        transportType: transportMode.value,
      );
      var saved = false;
      r.when(success: (_) => saved = true, error: (_) {});
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
        serverMessageOnly: true,
      );
      if (saved) Get.back(result: true);
    } finally {
      isBusy.value = false;
    }
  }

  void confirmDelete() {
    final ref = tripNoController.text.trim().isNotEmpty
        ? tripNoController.text.trim()
        : (mawbNoController.text.trim().isNotEmpty
            ? mawbNoController.text.trim()
            : linehaulId);
    commonDialog(
      OutboundLabels.deleteLinehaulTitle,
      OutboundLabels.deleteLinehaulConfirmMessage(ref),
      OutboundLabels.btnDelete,
      OutboundLabels.btnCancel,
      _deleteLinehaul,
      icon: Icons.delete_outline,
      iconColor: themes.redColor,
    );
  }

  Future<void> _deleteLinehaul() async {
    final id = linehaulIdController.text.trim();
    if (id.isEmpty) return;

    isBusy.value = true;
    try {
      final r = await _repo.deleteLinehaul(
        linehaulId: id,
        tripNo: tripNoController.text,
        mawbNo: mawbNoController.text,
      );
      var saved = false;
      r.when(success: (_) => saved = true, error: (_) {});
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
        serverMessageOnly: true,
      );
      if (saved) Get.back(result: true);
    } finally {
      isBusy.value = false;
    }
  }
}
