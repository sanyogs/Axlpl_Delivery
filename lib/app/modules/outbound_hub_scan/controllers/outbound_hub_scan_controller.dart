import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_log_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_table_row.dart';
import 'package:axlpl_delivery/app/data/models/outbound/shipment_scan_event_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/common_widget/common_tow_btn_dialog.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundHubScanController extends GetxController {
  OutboundHubScanController({
    OutboundRepository? repo,
    OutboundBranchListController? branchList,
  })  : _repo = repo ?? Get.find<OutboundRepository>(),
        _branchList = branchList ?? Get.find<OutboundBranchListController>();

  final OutboundRepository _repo;
  final OutboundBranchListController _branchList;

  final isBusy = false.obs;
  final isHubScanListLoading = false.obs;
  final fetchStatusMessage = ''.obs;
  final hubScanListError = ''.obs;
  final fetchedShipment = Rxn<HubScanFetchedShipment>();

  /// Staging queue: each entry is a snapshot of the form (not server logs).
  final sessionScannedRows = <HubScanTableRow>[].obs;
  final hubScanListAllRows = <HubScanLog>[].obs;
  final hubScanListPage = 1.obs;
  final hubScanListBranchId = ''.obs;
  final hubScanListBranchName = ''.obs;
  final scrollToSessionTable = 0.obs;
  final shipmentScanHistoryRows = <ShipmentScanEvent>[].obs;
  final isScanHistoryLoading = false.obs;

  static const hubScanListPageSize = 25;

  int get hubScanListTotalCount => hubScanListAllRows.length;

  int get hubScanListTotalPages {
    if (hubScanListAllRows.isEmpty) return 1;
    return (hubScanListAllRows.length / hubScanListPageSize).ceil();
  }

  List<HubScanLog> get hubScanListPageRows {
    if (hubScanListAllRows.isEmpty) return const [];
    final page = hubScanListPage.value.clamp(1, hubScanListTotalPages);
    final start = (page - 1) * hubScanListPageSize;
    if (start >= hubScanListAllRows.length) return const [];
    final end = start + hubScanListPageSize;
    return hubScanListAllRows.sublist(
      start,
      end > hubScanListAllRows.length ? hubScanListAllRows.length : end,
    );
  }

  int get hubScanListRowNumberOffset =>
      (hubScanListPage.value.clamp(1, hubScanListTotalPages) - 1) *
      hubScanListPageSize;

  String get hubScanListRangeLabel {
    final total = hubScanListTotalCount;
    if (total == 0) return '0 records';
    final page = hubScanListPage.value.clamp(1, hubScanListTotalPages);
    final start = (page - 1) * hubScanListPageSize + 1;
    final end = start + hubScanListPageRows.length - 1;
    return '$start–$end of $total';
  }

  void hubScanListGoToPage(int page) {
    hubScanListPage.value = page.clamp(1, hubScanListTotalPages);
  }

  void hubScanListNextPage() {
    if (hubScanListPage.value < hubScanListTotalPages) {
      hubScanListPage.value++;
    }
  }

  void hubScanListPreviousPage() {
    if (hubScanListPage.value > 1) {
      hubScanListPage.value--;
    }
  }

  final docketFocusNode = FocusNode();
  final docketController = TextEditingController();
  final clientCodeController = TextEditingController();
  final noOfBoxController = TextEditingController();
  final boxWeightController = TextEditingController();
  final originPincodeController = TextEditingController();
  final destPincodeController = TextEditingController();
  final destCityController = TextEditingController();

  final status = RxnString();
  final statuses = const ['HUB IN', 'HUB OUT'];

  String? _lastFetchedConnote;

  int get totalScanned => sessionScannedRows.length;

  int get totalParcels => sessionScannedRows.fold<int>(
        0,
        (sum, row) => sum + (int.tryParse(row.noOfBox ?? '') ?? 0),
      );

  @override
  void onInit() {
    super.onInit();
    status.value = 'HUB IN';
    docketFocusNode.addListener(_onDocketFocusChanged);
  }

  void _onDocketFocusChanged() {
    if (!docketFocusNode.hasFocus) {
      onDocketFocusLost();
    }
  }

  @override
  void onClose() {
    docketFocusNode.removeListener(_onDocketFocusChanged);
    docketFocusNode.dispose();
    docketController.dispose();
    clientCodeController.dispose();
    noOfBoxController.dispose();
    boxWeightController.dispose();
    originPincodeController.dispose();
    destPincodeController.dispose();
    destCityController.dispose();
    super.onClose();
  }

  void _setField(TextEditingController c, String? value) {
    c.text = value?.trim() ?? '';
  }

  void _applyShipmentToFields(HubScanFetchedShipment? shipment) {
    if (shipment == null) {
      _setField(clientCodeController, null);
      _setField(noOfBoxController, null);
      _setField(boxWeightController, null);
      _setField(originPincodeController, null);
      _setField(destPincodeController, null);
      _setField(destCityController, null);
      return;
    }
    _setField(clientCodeController, shipment.clientCode);
    _setField(noOfBoxController, shipment.numberOfParcel);
    _setField(boxWeightController, shipment.actualValue);
    _setField(originPincodeController, shipment.originPincode);
    _setField(destPincodeController, shipment.destinationPincode);
    _setField(destCityController, shipment.destinationCity);
  }

  void _clearDocketFieldsOnly() {
    docketController.clear();
    fetchedShipment.value = null;
    _lastFetchedConnote = null;
    _applyShipmentToFields(null);
    fetchStatusMessage.value = '';
  }

  String _statusForApi(String? uiStatus) {
    final s = uiStatus?.trim().toUpperCase() ?? '';
    if (s == 'HUB IN') return 'Hub In';
    if (s == 'HUB OUT') return 'Hub Out';
    return uiStatus?.trim() ?? '';
  }

  bool _canStageScan() {
    return true;
  }

  /// Push current form + shipment into Scanned Docket Details (staging).
  void _stageCurrentForm(HubScanFetchedShipment shipment) {
    if (!_canStageScan()) return;

    final row = HubScanTableRow.fromFormSnapshot(
      shipment: shipment,
      scanDocketTyped: docketController.text.trim(),
      scanType: status.value?.trim() ?? '',
      branchId: _branchList.selectedBranchIdOrNull ?? '',
    );
    final key = row.sessionKey;
    if (key.isEmpty) return;

    final next = List<HubScanTableRow>.from(sessionScannedRows);
    final idx = next.indexWhere((r) => r.sessionKey == key && !r.saved);
    if (idx >= 0) {
      next[idx] = row;
    } else {
      next.insert(0, row);
    }
    sessionScannedRows.assignAll(next);
    scrollToSessionTable.value++;
  }

  void _markSessionRowSaved(String sessionKey) {
    final key = sessionKey.trim();
    if (key.isEmpty) return;
    final next = sessionScannedRows
        .map((r) => r.sessionKey == key ? r.copyWith(saved: true) : r)
        .toList(growable: false);
    sessionScannedRows.assignAll(next);
  }

  /// Shows confirmation, then removes a staged docket (not allowed after save).
  void confirmRemoveSessionRow(String sessionKey) {
    final key = sessionKey.trim();
    if (key.isEmpty) return;
    HubScanTableRow? match;
    for (final r in sessionScannedRows) {
      if (r.sessionKey == key) {
        match = r;
        break;
      }
    }
    if (match == null || match.saved) return;

    final docket = match.docketNo?.trim();
    final display = (docket != null && docket.isNotEmpty) ? docket : key;

    commonDialog(
      OutboundLabels.deleteDocketTitle,
      OutboundLabels.deleteDocketConfirmMessage(display),
      OutboundLabels.btnDelete,
      OutboundLabels.btnCancel,
      () => _removeSessionRow(key),
      icon: Icons.delete_outline,
      iconColor: themes.redColor,
    );
  }

  void _removeSessionRow(String sessionKey) {
    final key = sessionKey.trim();
    if (key.isEmpty) return;
    HubScanTableRow? match;
    for (final r in sessionScannedRows) {
      if (r.sessionKey == key) {
        match = r;
        break;
      }
    }
    if (match == null || match.saved) return;
    sessionScannedRows.assignAll(
      sessionScannedRows
          .where((r) => r.sessionKey != key)
          .toList(growable: false),
    );
  }

  /// Leave Scan Docket No → fetch API → fill form → add snapshot below.
  Future<void> onDocketFocusLost() async {
    final connote = docketController.text.trim();
    if (connote.isEmpty) return;
    await fetchShipment(connoteOverride: connote);
  }

  Future<void> fetchShipment({String? connoteOverride}) async {
    final connote = (connoteOverride ?? docketController.text).trim();
    if (connote == _lastFetchedConnote && fetchedShipment.value != null) {
      return;
    }
    isBusy.value = true;
    fetchStatusMessage.value = '';
    try {
      final r = await _repo.hubScanFetchShipment(connote);
      r.when(
        success: (result) {
          final shipment = result.shipment;
          if (shipment == null) {
            fetchedShipment.value = null;
            _applyShipmentToFields(null);
            return;
          }
          fetchedShipment.value = shipment;
          _lastFetchedConnote = connote;
          _applyShipmentToFields(shipment);
          _stageCurrentForm(shipment);
          final msg = result.serverMessage?.trim() ?? '';
          fetchStatusMessage.value = msg;
          if (msg.isNotEmpty) {
            Get.snackbar('Hub scan', msg);
          }
        },
        error: (e) {
          fetchedShipment.value = null;
          _lastFetchedConnote = null;
          _applyShipmentToFields(null);
          final msg = e.message.trim();
          fetchStatusMessage.value = msg;
          if (msg.isNotEmpty) {
            Get.snackbar('Hub scan', msg);
          }
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> onConnoteScanned(String value) async {
    if (value.trim().isEmpty || value == '-1') return;
    docketController.text = value.trim();
    await fetchShipment(connoteOverride: value.trim());
  }

  bool get hubScanListShowsAllBranches => false;

  Future<bool> loadHubScanList() async {
    isHubScanListLoading.value = true;
    hubScanListError.value = '';
    hubScanListAllRows.clear();
    hubScanListPage.value = 1;
    try {
      final ctx = await OutboundAuthContext.load();
      final branchId = ctx.branchId?.trim();
      if (branchId == null || branchId.isEmpty) {
        hubScanListError.value = 'Messenger branch id is missing.';
        return false;
      }
      hubScanListBranchId.value = branchId;
      hubScanListBranchName.value = ctx.branchName?.trim() ?? '';
      _branchList.selectedBranchId.value = branchId;
      final APIResponse<List<HubScanLog>> r =
          await _repo.hubScanLogsFetchAll(branchId: branchId);
      return r.when(
        success: (rows) {
          hubScanListAllRows.assignAll(rows);
          if (rows.isEmpty) {
            final msg = _repo.lastMessage.trim();
            hubScanListError.value =
                msg.isNotEmpty ? msg : 'No hub scans found.';
          }
          return hubScanListError.value.isEmpty;
        },
        error: (e) {
          hubScanListError.value =
              e.message.trim().isNotEmpty ? e.message.trim() : 'Request failed';
          return false;
        },
      );
    } finally {
      isHubScanListLoading.value = false;
    }
  }

  /// Confirm — ready for next docket (row already staged below after fetch).
  Future<void> confirmHubScan() async {
    if (fetchedShipment.value != null) {
      _stageCurrentForm(fetchedShipment.value!);
    } else if (docketController.text.trim().isNotEmpty) {
      await fetchShipment();
      if (fetchedShipment.value != null) {
        _stageCurrentForm(fetchedShipment.value!);
      }
    }
    docketFocusNode.unfocus();
    _clearDocketFieldsOnly();
  }

  /// `getshipmentscanhistory` — uses current docket field as `docket_no`.
  Future<void> loadShipmentScanHistory() async {
    final docket = docketController.text.trim();
    isScanHistoryLoading.value = true;
    try {
      shipmentScanHistoryRows.clear();
      final rows = await _repo.shipmentScanHistory(docket);
      shipmentScanHistoryRows.assignAll(rows);
      if (rows.isEmpty) {
        final msg = _repo.lastMessage.trim();
        if (msg.isNotEmpty) Get.snackbar('Hub scan', msg);
      }
    } finally {
      isScanHistoryLoading.value = false;
    }
  }

  /// Save — hubscan API for every pending row in Scanned Docket Details.
  Future<void> saveHubScan() async {
    final pending =
        sessionScannedRows.where((r) => !r.saved).toList(growable: false);
    if (pending.isEmpty) return;

    isBusy.value = true;
    try {
      for (final row in pending) {
        final connote = row.shipmentId?.trim().isNotEmpty == true
            ? row.shipmentId!.trim()
            : (row.docketNo?.trim() ?? '');
        if (connote.isEmpty) continue;

        final branchId =
            row.branchId ?? _branchList.selectedBranchIdOrNull ?? '';
        final scanStatus = _statusForApi(row.scanType ?? status.value ?? '');

        final r = await _repo.hubScanSubmit(
          docketNo: connote,
          branchId: branchId,
          status: scanStatus,
        );
        var ok = false;
        r.when(
          success: (data) {
            ok = true;
            _markSessionRowSaved(row.sessionKey);
            final msg = OutboundUiFeedback.serverMessageFromData(data) ?? '';
            if (msg.isNotEmpty) {
              Get.snackbar('Hub scan', msg);
            }
          },
          error: (e) {
            final msg = e.message.trim();
            if (msg.isNotEmpty) Get.snackbar('Hub scan', msg);
          },
        );
        if (!ok) break;
      }
    } finally {
      isBusy.value = false;
    }
  }
}
