import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/common_widget/common_tow_btn_dialog.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Row in the bag details table on linehaul booking create.
class LinehaulBagTableRow {
  const LinehaulBagTableRow({
    required this.bagNumber,
    required this.weight,
  });

  final String bagNumber;
  final String weight;

  static List<LinehaulBagTableRow> fromManifestBags(List<ManifestBagRef> bags) {
    return bags
        .map(
          (b) => LinehaulBagTableRow(
            bagNumber: b.bagCode ?? b.metalSealNo ?? b.id ?? '—',
            weight: b.grossWeight ?? '—',
          ),
        )
        .toList();
  }
}

/// Linehaul booking create + list/detail helpers (admin pattern).
class OutboundLinehaulController extends GetxController {
  OutboundLinehaulController({
    OutboundRepository? repo,
  }) : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final isLinehaulListLoading = false.obs;
  final linehaulListError = ''.obs;
  final lastResponseText = ''.obs;

  final transportMode = OutboundLabels.modeAirway.obs;
  final manifestDetail = Rxn<ManifestDetail>();
  final linehaulRows = <OutboundLinehaulRow>[].obs;
  final linehaulDetail = Rxn<LinehaulDetail>();
  final bagTableRows = <LinehaulBagTableRow>[].obs;

  final listFilterStatus = RxnString();
  final updateStatus = RxnString();
  final selectedDestCityId = RxnString();
  final selectedOriginCityId = RxnString();
  final selectedListLinehaulRef = RxnString();

  static const listStatusOptions = [
    'In Transit',
    'Dispatched',
    'ARRIVED',
    'Completed',
  ];

  static const updateStatusOptions = [
    'ARRIVED',
    'In Transit',
    'Dispatched',
    'Completed',
  ];

  final manifestFocusNode = FocusNode();
  final manifestNoController = TextEditingController();
  final transportController = TextEditingController();
  final airwayBillController = TextEditingController();
  final ewayBillController = TextEditingController();
  final airwayBillDateController = TextEditingController();
  final airwayBillTimeController = TextEditingController();
  final noOfBagsController = TextEditingController();
  final totalWeightController = TextEditingController();
  final estArrivalDateController = TextEditingController();
  final estArrivalTimeController = TextEditingController();
  final totalCdWeightController = TextEditingController();
  final totalBillingWeightController = TextEditingController();
  final flightNoController = TextEditingController();
  final departureDateController = TextEditingController();
  final departureTimeController = TextEditingController();
  final linehaulRefController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();

  bool get isAirwayMode => transportMode.value == OutboundLabels.modeAirway;

  String get transportFieldLabel =>
      isAirwayMode ? OutboundLabels.airline : OutboundLabels.transport;

  @override
  void onInit() {
    super.onInit();
    manifestFocusNode.addListener(_onManifestFocusChanged);
  }

  void _onManifestFocusChanged() {
    if (!manifestFocusNode.hasFocus) {
      onManifestFocusLost();
    }
  }

  @override
  void onClose() {
    manifestFocusNode.removeListener(_onManifestFocusChanged);
    manifestFocusNode.dispose();
    manifestNoController.dispose();
    transportController.dispose();
    airwayBillController.dispose();
    ewayBillController.dispose();
    airwayBillDateController.dispose();
    airwayBillTimeController.dispose();
    noOfBagsController.dispose();
    totalWeightController.dispose();
    estArrivalDateController.dispose();
    estArrivalTimeController.dispose();
    totalCdWeightController.dispose();
    totalBillingWeightController.dispose();
    flightNoController.dispose();
    departureDateController.dispose();
    departureTimeController.dispose();
    linehaulRefController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    super.onClose();
  }

  void onTransportModeChanged(String mode) {
    transportMode.value = mode;
  }

  void onDestCityChanged(String? id) => selectedDestCityId.value = id;

  void onOriginCityChanged(String? id) => selectedOriginCityId.value = id;

  Future<void> onManifestFocusLost() async {
    final code = manifestNoController.text.trim();
    if (code.isEmpty) return;
    await getManifestDetails();
  }

  Future<void> onManifestSubmitted() => getManifestDetails();

  Future<void> onManifestScanned(String value) async {
    if (value.trim().isEmpty || value == '-1') return;
    manifestNoController.text = value.trim();
    await getManifestDetails();
  }

  Future<void> getManifestDetails() async {
    final code = manifestNoController.text.trim();
    if (code.isEmpty) return;

    isBusy.value = true;
    manifestDetail.value = null;
    bagTableRows.clear();
    try {
      final r = await _repo.fetchManifestDetails(code);
      r.when(
        success: (data) {
          final detail = ManifestDetail.fromDynamic(data);
          manifestDetail.value = detail;
          _applyManifestDetail(detail);
          lastResponseText.value = '';
          final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
          if (msg.isNotEmpty) Get.snackbar('Linehaul', msg);
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Linehaul', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  void _applyManifestDetail(ManifestDetail detail) {
    if (detail.destinationBranchId != null &&
        detail.destinationBranchId!.isNotEmpty) {
      selectedDestCityId.value = detail.destinationBranchId;
    }
    if (detail.originBranchId != null && detail.originBranchId!.isNotEmpty) {
      selectedOriginCityId.value = detail.originBranchId;
    }

    final bags = detail.bags;
    bagTableRows.assignAll(LinehaulBagTableRow.fromManifestBags(bags));
    noOfBagsController.text = bags.isEmpty ? '' : '${bags.length}';

    final totalBagWeight = _sumWeights(bags.map((b) => b.grossWeight));
    totalWeightController.text =
        totalBagWeight > 0 ? _formatWeight(totalBagWeight) : '';

    final cdWeight = _sumWeights(
      detail.shipments.map((s) => s.grossWeight),
    );
    final billingWeight = _sumBillingWeights(detail.shipments);
    if (cdWeight > 0) {
      totalCdWeightController.text = _formatWeight(cdWeight);
    }
    if (billingWeight > 0) {
      totalBillingWeightController.text = _formatWeight(billingWeight);
    }
  }

  static double _parseWeight(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return 0;
    return double.tryParse(t.replaceAll(',', '')) ?? 0;
  }

  static double _sumWeights(Iterable<String?> values) {
    var sum = 0.0;
    for (final v in values) {
      sum += _parseWeight(v);
    }
    return sum;
  }

  static double _sumBillingWeights(Iterable<ManifestShipmentRef> shipments) {
    var sum = 0.0;
    for (final s in shipments) {
      final gross = _parseWeight(s.grossWeight);
      final vol = _parseWeight(s.volumetricWeight);
      sum += gross > vol ? gross : vol;
    }
    return sum;
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
  }

  /// `assignlinehaul`: `vehicle_no` = MAWB (airway) or vehicle plate (surface).
  String _vehicleNoForAssign() {
    final airway = airwayBillController.text.trim();
    final transport = transportController.text.trim();
    if (isAirwayMode) return airway;
    if (transport.isNotEmpty) return transport;
    return airway;
  }

  /// `assignlinehaul`: `driver_name` = airline (airway) or driver name (surface).
  String _driverNameForAssign() {
    final transport = transportController.text.trim();
    final flight = flightNoController.text.trim();
    if (isAirwayMode) {
      if (transport.isNotEmpty) return transport;
      return flight;
    }
    if (transport.isNotEmpty) return transport;
    return flight;
  }

  Future<void> submitLinehaulBooking() async {
    final manifestCode = manifestNoController.text.trim();
    final airwayBill = airwayBillController.text.trim();
    final vehicleForAssign = _vehicleNoForAssign();
    final driverForAssign = _driverNameForAssign();

    if (manifestCode.isEmpty) {
      Get.snackbar('Linehaul', 'Manifest number is required');
      return;
    }
    if (vehicleForAssign.isEmpty) {
      Get.snackbar(
        'Linehaul',
        isAirwayMode
            ? 'Airway bill number is required'
            : 'Vehicle number is required',
      );
      return;
    }
    if (driverForAssign.isEmpty) {
      Get.snackbar(
        'Linehaul',
        '${isAirwayMode ? OutboundLabels.airline : OutboundLabels.transport} or ${OutboundLabels.flightNo} is required',
      );
      return;
    }

    isBusy.value = true;
    try {
      final assignR = await _repo.assignLinehaul(
        manifestIdsCommaSeparated: manifestCode,
        vehicleNo: vehicleForAssign,
        driverName: driverForAssign,
      );

      String? linehaulId;
      String? tripNo;
      assignR.when(
        success: (data) {
          final result = OutboundMutationResult.fromDynamic(data);
          linehaulId = result.linehaulId;
          tripNo = result.tripNo;
          final ref = result.effectiveLinehaulRef;
          if (ref != null && ref.isNotEmpty) {
            linehaulRefController.text = ref;
          }
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Linehaul', e.message);
        },
      );

      var id = linehaulId?.trim();
      if (id == null || id.isEmpty) {
        final lookupRef = airwayBill.isNotEmpty
            ? airwayBill
            : (tripNo?.trim().isNotEmpty == true ? tripNo!.trim() : null);
        if (lookupRef != null) {
          final detail = await _repo.linehaulDetails(lookupRef);
          id = detail?.linehaulId?.trim();
        }
      }
      if (id == null || id.isEmpty) {
        if (lastResponseText.value.trim().isEmpty) {
          Get.snackbar(
            'Linehaul',
            'Assign succeeded but linehaul_id missing — cannot save booking details',
          );
        }
        return;
      }

      final editR = await _repo.editLinehaul(
        linehaulId: id,
        vehicleNo: isAirwayMode ? null : vehicleForAssign,
        driverName: driverForAssign,
        mawbNo: airwayBill.isNotEmpty ? airwayBill : null,
        tripNo: tripNo?.trim().isNotEmpty == true ? tripNo : null,
        departureTime: OutboundApiParams.firstCombinedDateTime(
          departureDateController.text,
          departureTimeController.text,
          airwayBillDateController.text,
          airwayBillTimeController.text,
        ),
        arrivalTime: OutboundApiParams.combineDateTime(
          estArrivalDateController.text,
          estArrivalTimeController.text,
        ),
        flightNo: flightNoController.text.trim().isEmpty
            ? null
            : flightNoController.text.trim(),
        airline: transportController.text.trim().isEmpty
            ? null
            : transportController.text.trim(),
        ewayBill: ewayBillController.text.trim().isEmpty
            ? null
            : ewayBillController.text.trim(),
        transportType: transportMode.value,
        remarks: totalCdWeightController.text.trim().isNotEmpty ||
                totalBillingWeightController.text.trim().isNotEmpty
            ? 'CD: ${totalCdWeightController.text.trim()} Billing: ${totalBillingWeightController.text.trim()}'
            : null,
      );

      editR.when(
        success: (data) {
          lastResponseText.value = '';
          final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
          if (msg.isNotEmpty) Get.snackbar('Linehaul', msg);
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Linehaul', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> loadLinehaulList() async {
    isLinehaulListLoading.value = true;
    linehaulListError.value = '';
    linehaulRows.clear();
    try {
      final status = listFilterStatus.value?.trim() ?? '';
      final rows = await _repo.listLinehauls(status: status);
      linehaulRows.assignAll(rows);
      final msg = _repo.lastMessage.trim();
      if (msg.isNotEmpty) {
        linehaulListError.value = msg;
        return false;
      }
      return true;
    } catch (e) {
      linehaulListError.value = e.toString();
      return false;
    } finally {
      isLinehaulListLoading.value = false;
    }
  }

  Future<void> listLinehauls() async {
    await loadLinehaulList();
  }

  void applyLinehaulFromRow(OutboundLinehaulRow row) {
    final ref = row.effectiveRef;
    if (ref == null) return;
    linehaulRefController.text = ref;
    selectedListLinehaulRef.value = ref;
  }

  Future<void> getLinehaulDetails({String? refOverride}) async {
    final ref = (refOverride ?? linehaulRefController.text).trim();
    if (ref.isEmpty) return;

    isBusy.value = true;
    try {
      final r = await _repo.fetchLinehaulDetails(ref);
      r.when(
        success: (data) {
          final detail = LinehaulDetail.fromDynamic(data);
          linehaulDetail.value = detail;
          linehaulRefController.text =
              detail.tripNo ?? detail.airwayBillNo ?? ref;
          lastResponseText.value = '';
          final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
          if (msg.isNotEmpty) Get.snackbar('Linehaul', msg);
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Linehaul', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> openLinehaulDetailsFromList(OutboundLinehaulRow row) async {
    applyLinehaulFromRow(row);
    await getLinehaulDetails(refOverride: row.detailLookupRef);
  }

  Future<void> updateLinehaulStatus() async {
    final detail = linehaulDetail.value;
    final trip = detail?.linehaulId?.trim().isNotEmpty == true
        ? detail!.linehaulId!
        : linehaulRefController.text.trim();
    final newStatus = updateStatus.value?.trim() ?? '';
    if (trip.isEmpty || newStatus.isEmpty) return;

    isBusy.value = true;
    try {
      final ctx = await OutboundAuthContext.load();
      final branchId = OutboundAuthContext.branchIdForScan(ctx.branchId);
      final r = await _repo.updateLinehaulStatus(
        linehaulId: trip,
        status: newStatus,
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
        serverMessageOnly: true,
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> linehaulReport() async {
    isBusy.value = true;
    try {
      final r = await _repo.linehaulReport(
        startDate: reportStartController.text.trim(),
        endDate: reportEndController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
      );
    } finally {
      isBusy.value = false;
    }
  }

  void openLinehaulDetailPage() {
    final ref = linehaulDetail.value?.detailLookupRef ??
        linehaulRefController.text.trim();
    if (ref.isEmpty) return;
    Get.toNamed(
      Routes.OUTBOUND_REMOTE_DETAIL,
      arguments: {'kind': 'linehaul', 'id': ref},
    );
  }

  Future<void> openLinehaulEdit(OutboundLinehaulRow row) async {
    final id = row.linehaulId?.trim();
    if (id == null || id.isEmpty) {
      Get.snackbar('Linehaul', 'Linehaul id missing for this row');
      return;
    }
    final refreshed = await Get.toNamed(
      Routes.OUTBOUND_LINEHAUL_EDIT,
      arguments: row,
    );
    if (refreshed == true) {
      await loadLinehaulList();
    }
  }

  void confirmDeleteLinehaulFromList(OutboundLinehaulRow row) {
    final id = row.linehaulId?.trim();
    if (id == null || id.isEmpty) {
      Get.snackbar('Linehaul', 'Linehaul id missing for this row');
      return;
    }
    final ref = row.tripNo?.trim().isNotEmpty == true
        ? row.tripNo!
        : (row.mawbNo?.trim().isNotEmpty == true ? row.mawbNo! : id);
    commonDialog(
      OutboundLabels.deleteLinehaulTitle,
      OutboundLabels.deleteLinehaulConfirmMessage(ref),
      OutboundLabels.btnDelete,
      OutboundLabels.btnCancel,
      () => _deleteLinehaulFromList(id),
      icon: Icons.delete_outline,
      iconColor: themes.redColor,
    );
  }

  Future<void> _deleteLinehaulFromList(String linehaulId) async {
    isBusy.value = true;
    try {
      final r = await _repo.deleteLinehaul(linehaulId: linehaulId);
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
        serverMessageOnly: true,
      );
      var deleted = false;
      r.when(success: (_) => deleted = true, error: (_) {});
      if (deleted) {
        if (selectedListLinehaulRef.value != null) {
          selectedListLinehaulRef.value = null;
          linehaulDetail.value = null;
        }
        await loadLinehaulList();
      }
    } finally {
      isBusy.value = false;
    }
  }
}
