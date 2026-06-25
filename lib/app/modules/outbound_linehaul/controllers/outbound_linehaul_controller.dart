import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_airline_list_controller.dart';
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

  static List<LinehaulBagTableRow> fromManifestDetail(ManifestDetail detail) {
    final weightByBag = <String, double>{};
    for (final s in detail.shipments) {
      final keys = <String>{
        if (s.bagCode?.trim().isNotEmpty == true) s.bagCode!.trim(),
        if (s.bagId?.trim().isNotEmpty == true) s.bagId!.trim(),
      };
      final w = _parseWeight(s.grossWeight);
      if (w <= 0) continue;
      for (final key in keys) {
        weightByBag[key] = (weightByBag[key] ?? 0) + w;
      }
    }

    return detail.bags
        .map(
          (b) {
            final bagNumber = b.bagCode ?? b.metalSealNo ?? b.id ?? '—';
            final keys = <String?>[
              b.bagCode,
              b.id,
              b.metalSealNo,
            ];
            var weight = _parseWeight(b.grossWeight);
            if (weight <= 0) {
              for (final key in keys) {
                final k = key?.trim();
                if (k == null || k.isEmpty) continue;
                final fromShip = weightByBag[k];
                if (fromShip != null && fromShip > 0) {
                  weight = fromShip;
                  break;
                }
              }
            }
            return LinehaulBagTableRow(
              bagNumber: bagNumber,
              weight: weight > 0 ? _formatWeight(weight) : '—',
            );
          },
        )
        .toList();
  }

  static double _parseWeight(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return 0;
    return double.tryParse(t.replaceAll(',', '')) ?? 0;
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toStringAsFixed(2);
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
  final linehaulListPage = 1.obs;
  final linehaulDetail = Rxn<LinehaulDetail>();
  final bagTableRows = <LinehaulBagTableRow>[].obs;
  final manifestLoadRevision = 0.obs;

  final listFilterStatus = RxnString();
  final updateStatus = RxnString();
  final selectedDestCityId = RxnString();
  final selectedOriginCityId = RxnString();
  final selectedListLinehaulRef = RxnString();
  final selectedAirlineId = RxnString();

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

  static const linehaulListPageSize = 20;

  int get linehaulListTotalCount => linehaulRows.length;

  int get linehaulListTotalPages {
    if (linehaulRows.isEmpty) return 1;
    return (linehaulRows.length / linehaulListPageSize).ceil();
  }

  List<OutboundLinehaulRow> get linehaulListPageRows {
    final rows = linehaulRows;
    if (rows.isEmpty) return const [];
    final page = linehaulListPage.value.clamp(1, linehaulListTotalPages);
    final start = (page - 1) * linehaulListPageSize;
    if (start >= rows.length) return const [];
    final end = start + linehaulListPageSize;
    final cappedEnd = end > rows.length ? rows.length : end;
    return rows.sublist(start, cappedEnd);
  }

  int get linehaulListRowNumberOffset =>
      (linehaulListPage.value.clamp(1, linehaulListTotalPages) - 1) *
      linehaulListPageSize;

  String get linehaulListRangeLabel {
    final total = linehaulListTotalCount;
    if (total == 0) return '0 records';
    final page = linehaulListPage.value.clamp(1, linehaulListTotalPages);
    final start = (page - 1) * linehaulListPageSize + 1;
    final end = start + linehaulListPageRows.length - 1;
    return '$start–$end of $total';
  }

  void linehaulListGoToPage(int page) {
    linehaulListPage.value = page.clamp(1, linehaulListTotalPages);
  }

  void linehaulListNextPage() {
    if (linehaulListPage.value < linehaulListTotalPages) {
      linehaulListPage.value++;
    }
  }

  void linehaulListPreviousPage() {
    if (linehaulListPage.value > 1) linehaulListPage.value--;
  }

  final manifestFocusNode = FocusNode();
  final manifestNoController = TextEditingController();
  final transportController = TextEditingController();
  final airlineController = TextEditingController();
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

  String get mawbVehicleFieldLabel =>
      isAirwayMode ? OutboundLabels.airwayBillNo : OutboundLabels.vehicleNo;

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
    airlineController.dispose();
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
    if (mode != OutboundLabels.modeAirway) {
      selectedAirlineId.value = null;
    } else if (airlineController.text.trim().isNotEmpty) {
      selectedAirlineId.value = _resolveAirlineId(airlineController.text);
    }
  }

  void onDestCityChanged(String? id) => selectedDestCityId.value = id;

  void onOriginCityChanged(String? id) => selectedOriginCityId.value = id;

  void onAirlineChanged(String? id) {
    final resolved = _resolveAirlineId(id);
    selectedAirlineId.value = resolved;
    airlineController.text = resolved ?? '';
  }

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

    final existing = manifestDetail.value;
    isBusy.value = true;
    manifestDetail.value = null;
    bagTableRows.clear();
    try {
      final r = await _repo.fetchManifestDetailsByRefs([
        code,
        existing?.manifestNo,
        existing?.manifestId,
      ]);
      r.when(
        success: (data) {
          final detail = ManifestDetail.fromDynamic(data);
          if (!detail.hasContent) {
            lastResponseText.value = OutboundDataParse.pretty(data);
            Get.snackbar('Linehaul', 'Manifest details not found');
            return;
          }
          manifestDetail.value = detail;
          _applyManifestDetail(detail);
          lastResponseText.value = '';
          final msg =
              OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
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

  static void _applyDateTimeFromApi(
    String? raw,
    TextEditingController date,
    TextEditingController time,
  ) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return;
    final parts = t.split(' ');
    if (parts.isNotEmpty) date.text = parts[0];
    if (parts.length > 1) {
      final hm = parts[1];
      time.text = hm.length >= 5 ? hm.substring(0, 5) : hm;
    }
  }

  void _applyManifestDetail(ManifestDetail detail) {
    final manifestNo = detail.manifestNo?.trim();
    if (manifestNo != null && manifestNo.isNotEmpty) {
      manifestNoController.text = manifestNo;
    }
    if (detail.destinationBranchId != null &&
        detail.destinationBranchId!.isNotEmpty) {
      selectedDestCityId.value = detail.destinationBranchId;
    }
    if (detail.originBranchId != null && detail.originBranchId!.isNotEmpty) {
      selectedOriginCityId.value = detail.originBranchId;
    }

    final manifestTimestamp = detail.createdAt?.trim().isNotEmpty == true
        ? detail.createdAt
        : detail.updatedAt;
    _applyDateTimeFromApi(
      manifestTimestamp,
      airwayBillDateController,
      airwayBillTimeController,
    );
    _applyDateTimeFromApi(
      manifestTimestamp,
      departureDateController,
      departureTimeController,
    );

    final bags = detail.bags;
    bagTableRows.assignAll(LinehaulBagTableRow.fromManifestDetail(detail));
    noOfBagsController.text = bags.isEmpty ? '' : '${bags.length}';

    var totalWeight = _sumWeights(bags.map((b) => b.grossWeight));
    if (totalWeight <= 0) {
      totalWeight = _sumWeights(
        detail.shipments.map((s) => s.grossWeight),
      );
    }
    if (totalWeight <= 0) {
      totalWeight = _parseWeight(detail.totalWeight);
    }
    final weightText = totalWeight > 0 ? _formatWeight(totalWeight) : '';
    totalWeightController.text = weightText;

    final cdWeight = _sumWeights(
      detail.shipments.map((s) => s.grossWeight),
    );
    final billingWeight = _sumBillingWeights(detail.shipments);
    if (cdWeight > 0) {
      totalCdWeightController.text = _formatWeight(cdWeight);
    } else if (weightText.isNotEmpty) {
      totalCdWeightController.text = weightText;
    }
    if (billingWeight > 0) {
      totalBillingWeightController.text = _formatWeight(billingWeight);
    } else if (weightText.isNotEmpty) {
      totalBillingWeightController.text = weightText;
    }

    manifestLoadRevision.value++;
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
    return airwayBillController.text.trim();
  }

  String _airlineForApi() {
    final selected = selectedAirlineId.value?.trim();
    if (isAirwayMode && selected != null && selected.isNotEmpty) {
      return _resolveAirlineId(selected) ?? selected;
    }
    if (isAirwayMode) {
      final raw = airlineController.text.trim();
      return _resolveAirlineId(raw) ?? raw;
    }
    return transportController.text.trim();
  }

  String? _resolveAirlineId(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (Get.isRegistered<OutboundAirlineListController>()) {
      return Get.find<OutboundAirlineListController>().resolveId(raw);
    }
    return raw;
  }

  /// `assignlinehaul`: `driver_name` = airline (airway) or driver name (surface).
  String _driverNameForAssign() {
    final transport = _airlineForApi();
    final flight = flightNoController.text.trim();
    if (isAirwayMode) {
      if (transport.isNotEmpty) return transport;
      return flight;
    }
    if (transport.isNotEmpty) return transport;
    return flight;
  }

  Future<void> submitLinehaulBooking() async {
    final manifestCode = _manifestRefForSubmit();
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

      var assignSucceeded = false;
      String? tripNo;
      String? linehaulRef;
      String? numericLinehaulId;
      assignR.when(
        success: (data) {
          assignSucceeded = true;
          final result = OutboundMutationResult.fromDynamic(data);
          tripNo = result.tripNo;
          numericLinehaulId = result.numericLinehaulIdForEdit;
          linehaulRef = result.effectiveLinehaulRef;
          if (linehaulRef != null && linehaulRef!.isNotEmpty) {
            linehaulRefController.text = linehaulRef!;
          }
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Linehaul', e.message);
        },
      );

      if (!assignSucceeded) return;

      final id = await _resolveLinehaulIdForEdit(
        numericLinehaulId: numericLinehaulId,
        linehaulRef: linehaulRef,
        tripNo: tripNo,
        airwayBill: airwayBill,
      );
      if (id == null || id.isEmpty) {
        Get.snackbar(
          'Linehaul',
          'Assign succeeded but linehaul id could not be resolved for booking',
        );
        return;
      }

      final editR = await _repo.editLinehaul(
        linehaulId: id,
        vehicleNo: isAirwayMode ? null : vehicleForAssign,
        driverName: driverForAssign,
        mawbNo: airwayBill.isNotEmpty ? airwayBill : null,
        tripNo: tripNo?.trim().isNotEmpty == true ? tripNo!.trim() : null,
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
        airline: _airlineForApi().isEmpty ? null : _airlineForApi(),
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
          final msg =
              OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
          Get.snackbar(
            'Linehaul',
            msg.isNotEmpty ? msg : 'Linehaul booking saved',
          );
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
      linehaulListPage.value = 1;
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
          final msg =
              OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
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

  String _manifestRefForSubmit() {
    final detail = manifestDetail.value;
    final code = detail?.manifestNo?.trim();
    if (code != null && code.isNotEmpty) return code;
    final id = detail?.manifestId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return manifestNoController.text.trim();
  }

  /// `editlinehaul` requires numeric `linehaul_id`; `LH…` trip refs must be resolved via `getlinehauldetails`.
  Future<String?> _resolveLinehaulIdForEdit({
    String? numericLinehaulId,
    required String? linehaulRef,
    required String? tripNo,
    required String airwayBill,
  }) async {
    final assignId = numericLinehaulId?.trim();
    if (assignId != null &&
        assignId.isNotEmpty &&
        assignId != '0' &&
        !OutboundApiParams.looksLikeTripNo(assignId)) {
      return assignId;
    }

    var id = linehaulRef?.trim();
    if (id != null &&
        id.isNotEmpty &&
        id != '0' &&
        !OutboundApiParams.looksLikeTripNo(id)) {
      return id;
    }

    final trip = tripNo?.trim();
    final lookupRef = trip != null && trip.isNotEmpty
        ? trip
        : (id != null && OutboundApiParams.looksLikeTripNo(id))
            ? id
            : (airwayBill.isNotEmpty ? airwayBill : null);
    if (lookupRef == null) return null;

    final detail = await _repo.linehaulDetails(lookupRef);
    final numericId = detail?.linehaulId?.trim();
    if (numericId != null && numericId.isNotEmpty && numericId != '0') {
      return numericId;
    }
    return null;
  }

  Future<void> openLinehaulDetailsFromList(OutboundLinehaulRow row) async {
    openLinehaulPreAlertFromList(row);
  }

  void openLinehaulPreAlertFromList(OutboundLinehaulRow row) {
    final ref = row.detailLookupRef;
    if (ref == null || ref.isEmpty) {
      Get.snackbar('Linehaul', 'Linehaul reference missing for this row');
      return;
    }
    Get.toNamed(
      Routes.OUTBOUND_LINEHAUL_PRE_ALERT,
      arguments: {'ref': ref},
    );
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
    final id = row.deleteRef?.trim();
    if (id == null || id.isEmpty) {
      Get.snackbar('Linehaul', 'Linehaul reference missing for this row');
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
      () => _deleteLinehaulFromList(
        id,
        tripNo: row.tripNo,
        mawbNo: row.mawbNo,
      ),
      icon: Icons.delete_outline,
      iconColor: themes.redColor,
    );
  }

  Future<void> _deleteLinehaulFromList(
    String linehaulId, {
    String? tripNo,
    String? mawbNo,
  }) async {
    isBusy.value = true;
    try {
      final r = await _repo.deleteLinehaul(
        linehaulId: linehaulId,
        tripNo: tripNo,
        mawbNo: mawbNo,
      );
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
