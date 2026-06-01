import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_table_row.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/networking/api_exception.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bagging — each visible field maps to a Postman / QA parameter (see module validation).
class OutboundBaggingController extends GetxController {
  OutboundBaggingController({
    OutboundRepository? repo,
    OutboundBranchListController? branchList,
  })  : _repo = repo ?? Get.find<OutboundRepository>(),
        _branchList = branchList ?? Get.find<OutboundBranchListController>();

  final OutboundRepository _repo;
  final OutboundBranchListController _branchList;

  final isBusy = false.obs;
  final isBagListLoading = false.obs;
  final bagListError = ''.obs;
  final fetchStatusMessage = ''.obs;
  final fetchedShipment = Rxn<HubScanFetchedShipment>();
  final bagDetail = Rxn<BagDetail>();
  final baggingReportData = Rxn<BaggingReport>();

  final sessionScannedRows = <BaggingTableRow>[].obs;
  final bagListAllRows = <OutboundBagRow>[].obs;
  final bagListPage = 1.obs;
  final scrollToScannedTable = 0.obs;

  static const bagListPageSize = 25;

  final shipmentFocusNode = FocusNode();
  final bagCodeFocusNode = FocusNode();
  final metalSealController = TextEditingController();
  final bagCodeWorkingController = TextEditingController();
  final shipmentController = TextEditingController();
  final reportBagCodeController = TextEditingController();

  final selectedOriginDepotId = RxnString();
  final selectedDestDepotId = RxnString();

  String? _lastFetchedShipmentId;
  String? _depotContextKey;
  String? _loadedBagCode;

  List<OutboundBagRow> get bagListFilteredRows {
    final dest = _destId;
    if (dest == null || dest.isEmpty) return bagListAllRows;
    return bagListAllRows
        .where((r) => _destinationIdForRow(r) == dest)
        .toList();
  }

  int get bagListTotalCount => bagListFilteredRows.length;

  int get bagListTotalPages {
    if (bagListFilteredRows.isEmpty) return 1;
    return (bagListFilteredRows.length / bagListPageSize).ceil();
  }

  List<OutboundBagRow> get bagListPageRows {
    final filtered = bagListFilteredRows;
    if (filtered.isEmpty) return const [];
    final page = bagListPage.value.clamp(1, bagListTotalPages);
    final start = (page - 1) * bagListPageSize;
    if (start >= filtered.length) return const [];
    final end = start + bagListPageSize;
    return filtered.sublist(end > filtered.length ? filtered.length : end);
  }

  int get bagListRowNumberOffset =>
      (bagListPage.value.clamp(1, bagListTotalPages) - 1) * bagListPageSize;

  String get bagListRangeLabel {
    final total = bagListTotalCount;
    if (total == 0) return '0 records';
    final page = bagListPage.value.clamp(1, bagListTotalPages);
    final start = (page - 1) * bagListPageSize + 1;
    final end = start + bagListPageRows.length - 1;
    return '$start–$end of $total';
  }

  String get selectedDepotSummary {
    final origin = _branchList.displayLabelForId(_originId);
    final dest = _branchList.displayLabelForId(_destId);
    if (_originId == null && _destId == null) return '';
    return 'Origin: $origin → Destination: $dest';
  }

  /// True when `bag_code` came from server — field stays read-only.
  bool get isBagCodeFromServer =>
      _loadedBagCode != null && _loadedBagCode!.isNotEmpty;

  List<BaggingTableRow> get scannedBoxRows {
    final rows = <BaggingTableRow>[];
    final pendingKeys = <String>{};
    final destLabel = _destinationLabel();

    for (final r in sessionScannedRows) {
      if (r.sessionKey.isEmpty) continue;
      pendingKeys.add(r.sessionKey);
      rows.add(r);
    }

    final detail = bagDetail.value;
    final savedDestLabel = detail == null
        ? destLabel
        : _labelForDestinationSector(
            sectorId: detail.destinationSectorId,
            sectorName: detail.destinationSectorName,
            fallback: destLabel,
          );

    if (detail != null) {
      for (final item in detail.items) {
        final key = item.shipmentId?.trim() ?? '';
        if (key.isNotEmpty && pendingKeys.contains(key)) continue;
        rows.add(
          BaggingTableRow.fromBagDetailItem(
            item,
            destination: savedDestLabel,
          ),
        );
      }
    }
    return rows;
  }

  int get totalScannedBoxes => scannedBoxRows.length;

  @override
  void onInit() {
    super.onInit();
    shipmentFocusNode.addListener(_onShipmentFocusChanged);
    bagCodeFocusNode.addListener(_onBagCodeFocusChanged);
    ever(_branchList.isLoadingBranches, (loading) {
      if (loading == false && _originId != null && _workingBagCode != null) {
        refreshBagDetailsQuiet();
      }
    });
    _depotContextKey = _buildDepotContextKey();
  }

  void _onShipmentFocusChanged() {
    if (!shipmentFocusNode.hasFocus) {
      onShipmentFocusLost();
    }
  }

  void _onBagCodeFocusChanged() {
    if (!bagCodeFocusNode.hasFocus) {
      onBagCodeFocusLost();
    }
  }

  @override
  void onClose() {
    shipmentFocusNode.removeListener(_onShipmentFocusChanged);
    bagCodeFocusNode.removeListener(_onBagCodeFocusChanged);
    shipmentFocusNode.dispose();
    bagCodeFocusNode.dispose();
    metalSealController.dispose();
    bagCodeWorkingController.dispose();
    shipmentController.dispose();
    reportBagCodeController.dispose();
    super.onClose();
  }

  String? get _originId => selectedOriginDepotId.value?.trim();
  String? get _destId => selectedDestDepotId.value?.trim();

  String? get _workingBagCode {
    final code = bagCodeWorkingController.text.trim();
    if (code.isEmpty) return null;
    return code;
  }

  String _destinationLabel() =>
      _branchList.displayLabelForId(selectedDestDepotId.value);

  String _labelForDestinationSector({
    required String? sectorId,
    required String? sectorName,
    required String fallback,
  }) {
    final name = sectorName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (sectorId != null && sectorId.trim().isNotEmpty) {
      return _branchList.displayLabelForId(sectorId.trim());
    }
    return fallback;
  }

  static String? _destinationIdForRow(OutboundBagRow row) =>
      row.destinationSectorId ?? row.destinationBranchId;

  String _buildDepotContextKey() => '${_originId ?? ''}|${_destId ?? ''}';

  /// Snackbar text from API `message` / `__server_message` only — never client copy.
  void _snackServerData(dynamic data) {
    final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
    if (msg.isNotEmpty) Get.snackbar('Bagging', msg);
  }

  void _snackServerError(AppException e) {
    final msg = e.message.trim();
    if (msg.isNotEmpty) Get.snackbar('Bagging', msg);
  }

  void onOriginDepotChanged(String? id) {
    selectedOriginDepotId.value = id;
    _onDepotContextChanged();
    _branchList.showLoadIssueIfNeeded();
  }

  void onDestinationDepotChanged(String? id) {
    selectedDestDepotId.value = id;
    _onDepotContextChanged();
  }

  void _onDepotContextChanged() {
    final next = _buildDepotContextKey();
    if (_depotContextKey == next) return;
    _depotContextKey = next;
    sessionScannedRows.clear();
    bagDetail.value = null;
    bagCodeWorkingController.clear();
    _loadedBagCode = null;
    bagListAllRows.clear();
    bagListPage.value = 1;
    bagListError.value = '';
    fetchedShipment.value = null;
    _lastFetchedShipmentId = null;
    fetchStatusMessage.value = '';
    shipmentController.clear();
  }

  void _applyBagDetailToSelection(BagDetail detail) {
    if (detail.originBranchId != null && detail.originBranchId!.isNotEmpty) {
      selectedOriginDepotId.value = detail.originBranchId;
    }
    if (detail.destinationSectorId != null &&
        detail.destinationSectorId!.isNotEmpty) {
      selectedDestDepotId.value = detail.destinationSectorId;
    }
    if (detail.metalSealNo != null && detail.metalSealNo!.isNotEmpty) {
      metalSealController.text = detail.metalSealNo!;
    }
    if (detail.bagCode != null && detail.bagCode!.isNotEmpty) {
      bagCodeWorkingController.text = detail.bagCode!;
      _loadedBagCode = detail.bagCode;
    }
    _depotContextKey = _buildDepotContextKey();
  }

  void _stageCurrentShipment(HubScanFetchedShipment shipment) {
    final row = BaggingTableRow.fromFetchedShipment(
      shipment: shipment,
      scanTyped: shipmentController.text.trim(),
      destination: _destinationLabel(),
      saved: false,
    );
    if (row.sessionKey.isEmpty) return;

    final next = List<BaggingTableRow>.from(sessionScannedRows);
    final idx = next.indexWhere((r) => r.sessionKey == row.sessionKey && !r.saved);
    if (idx >= 0) {
      next[idx] = row;
    } else {
      next.insert(0, row);
    }
    sessionScannedRows.assignAll(next);
    scrollToScannedTable.value++;
  }

  Future<void> onShipmentFocusLost() async {
    final id = shipmentController.text.trim();
    if (id.isEmpty) return;
    await fetchShipment(shipmentOverride: id);
  }

  Future<void> onBagCodeFocusLost() async {
    await loadBagByCode();
  }

  /// `getbagdetails` — uses Bag Code field → `bag_code` query param.
  Future<void> loadBagByCode() async {
    final code = bagCodeWorkingController.text.trim();
    if (code.isEmpty) {
      _loadedBagCode = null;
      bagDetail.value = null;
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.fetchBagDetails(code);
      r.when(
        success: (data) {
          final detail = BagDetail.fromDynamic(data);
          bagDetail.value = detail;
          _applyBagDetailToSelection(detail);
          sessionScannedRows.clear();
          _snackServerData(data);
        },
        error: _snackServerError,
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> fetchShipment({String? shipmentOverride}) async {
    final connote = (shipmentOverride ?? shipmentController.text).trim();
    if (connote == _lastFetchedShipmentId && fetchedShipment.value != null) {
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
            return;
          }
          fetchedShipment.value = shipment;
          _lastFetchedShipmentId = connote;
          _stageCurrentShipment(shipment);
          final msg = result.serverMessage?.trim() ?? '';
          fetchStatusMessage.value = msg;
          if (msg.isNotEmpty) Get.snackbar('Bagging', msg);
        },
        error: (e) {
          fetchedShipment.value = null;
          _lastFetchedShipmentId = null;
          final msg = e.message.trim();
          fetchStatusMessage.value = msg;
          if (msg.isNotEmpty) Get.snackbar('Bagging', msg);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> onShipmentScanned(String value) async {
    if (value.trim().isEmpty || value == '-1') return;
    shipmentController.text = value.trim();
    await fetchShipment(shipmentOverride: value.trim());
  }

  Future<void> onBagCodeScanned(String value) async {
    if (value.trim().isEmpty || value == '-1') return;
    bagCodeWorkingController.text = value.trim();
    await loadBagByCode();
  }

  Future<void> confirmBagging() async {
    if (fetchedShipment.value != null) {
      _stageCurrentShipment(fetchedShipment.value!);
    } else if (shipmentController.text.trim().isNotEmpty) {
      await fetchShipment();
    }

    final pending =
        sessionScannedRows.where((r) => !r.saved).toList(growable: false);
    if (pending.isNotEmpty) {
      final saved = await _savePendingShipments();
      if (!saved) return;
    }

    final bagCode = _workingBagCode?.trim() ?? '';
    if (bagCode.isEmpty) return;

    isBusy.value = true;
    try {
      await refreshBagDetailsQuiet();
      scrollToScannedTable.value++;

      final r = await _repo.lockBag(bagCode);
      await r.when(
        success: (data) async {
          _snackServerData(data);
          await refreshBagDetailsQuiet();
          scrollToScannedTable.value++;
          shipmentController.clear();
          fetchedShipment.value = null;
          _lastFetchedShipmentId = null;
          fetchStatusMessage.value = '';
        },
        error: (e) async {
          _snackServerError(e);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> saveBagging() async {
    await _savePendingShipments();
  }

  bool _isExistingBagSession() {
    final code = _workingBagCode?.trim();
    return code != null && code.isNotEmpty;
  }

  Future<bool> _savePendingShipments() async {
    final origin = _originId ?? '';
    final dest = _destId ?? '';
    final metalSeal = metalSealController.text.trim();

    final pending =
        sessionScannedRows.where((r) => !r.saved).toList(growable: false);

    isBusy.value = true;
    var savedCount = 0;
    var ok = true;
    try {
      if (_isExistingBagSession()) {
        final bagCode = _workingBagCode!;
        if (bagDetail.value == null) {
          await loadBagByCode();
          if (bagDetail.value == null) return false;
        }

        for (final row in pending) {
          final docket = row.docketForApi;
          final r = await _repo.addShipmentToBag(
            bagId: bagCode,
            docketNo: docket,
            branchId: origin,
          );
          var rowOk = false;
          r.when(
            success: (data) {
              rowOk = true;
              savedCount++;
              _snackServerData(data);
            },
            error: (e) {
              ok = false;
              _snackServerError(e);
            },
          );
          if (!rowOk) break;
        }
        if (savedCount > 0) {
          final loaded = await refreshBagDetailsQuiet();
          if (loaded) {
            sessionScannedRows.clear();
            scrollToScannedTable.value++;
          }
        } else if (pending.isEmpty) {
          ok = true;
        } else {
          ok = false;
        }
      } else {
        final ids = pending.map((r) => r.docketForApi).where((s) => s.isNotEmpty).toList();
        final customBagCode = _workingBagCode;
        String? createBagCode;
        if (customBagCode != null && customBagCode.isNotEmpty) {
          createBagCode = customBagCode;
        }

        final r = await _repo.createBag(
          originBranchId: origin,
          destinationBranchId: dest,
          metalSealNo: metalSeal,
          shipmentIdsCsv: OutboundApiParams.shipmentIdsCsv(ids),
          bagCode: createBagCode,
        );
        var created = false;
        r.when(
          success: (data) {
            created = true;
            savedCount = ids.length;
            final result = OutboundMutationResult.fromDynamic(data);
            final ref = result.effectiveBagRef;
            if (ref != null && ref.isNotEmpty) {
              bagCodeWorkingController.text = ref;
              _loadedBagCode = ref;
            }
            final seal = result.metalSealNo?.trim();
            if (seal != null && seal.isNotEmpty) {
              metalSealController.text = seal;
            }
            _snackServerData(data);
          },
          error: (e) {
            ok = false;
            _snackServerError(e);
          },
        );
        if (!created) return false;
        final loaded = await refreshBagDetailsQuiet();
        if (loaded) {
          sessionScannedRows.clear();
          scrollToScannedTable.value++;
        }
      }
    } finally {
      isBusy.value = false;
    }
    return ok;
  }

  Future<bool> refreshBagDetailsQuiet() async {
    final code = _workingBagCode;
    if (code == null) return false;
    final r = await _repo.fetchBagDetails(code);
    return r.when(
      success: (data) {
        final detail = BagDetail.fromDynamic(data);
        bagDetail.value = detail;
        _applyBagDetailToSelection(detail);
        return true;
      },
      error: (_) => false,
    );
  }

  void removeScannedRow(BaggingTableRow row) {
    final key = row.sessionKey;
    if (key.isEmpty) return;

    if (!row.saved) {
      sessionScannedRows.assignAll(
        sessionScannedRows.where((r) => r.sessionKey != key).toList(),
      );
      return;
    }

    final origin = _originId;
    final bagCode = _workingBagCode;
    if (origin == null || origin.isEmpty || bagCode == null || bagCode.isEmpty) {
      _removeShipmentFromBag(
        bagCode: bagCode ?? '',
        docket: row.docketForApi,
        branchId: origin ?? '',
      );
      return;
    }

    _removeShipmentFromBag(
      bagCode: bagCode,
      docket: row.docketForApi,
      branchId: origin,
    );
  }

  Future<void> _removeShipmentFromBag({
    required String bagCode,
    required String docket,
    required String branchId,
  }) async {
    isBusy.value = true;
    try {
      final r = await _repo.removeShipmentFromBag(
        bagId: bagCode,
        docketNo: docket,
        branchId: branchId,
      );
      r.when(
        success: (_) async {
          await refreshBagDetailsQuiet();
        },
        error: _snackServerError,
      );
    } finally {
      isBusy.value = false;
    }
  }

  void bagListGoToPage(int page) {
    bagListPage.value = page.clamp(1, bagListTotalPages);
  }

  void bagListNextPage() {
    if (bagListPage.value < bagListTotalPages) bagListPage.value++;
  }

  void bagListPreviousPage() {
    if (bagListPage.value > 1) bagListPage.value--;
  }

  Future<bool> loadBagList() async {
    isBagListLoading.value = true;
    bagListError.value = '';
    bagListAllRows.clear();
    bagListPage.value = 1;
    try {
      final rows = await _repo.listBags(branchId: _originId ?? '');
      bagListAllRows.assignAll(rows);
      final filtered = bagListFilteredRows;
      if (filtered.isEmpty) {
        bagListError.value = _repo.lastMessage.trim();
      }
      return bagListError.value.isEmpty;
    } catch (e) {
      bagListError.value = e.toString();
      return false;
    } finally {
      isBagListLoading.value = false;
    }
  }

  void applyBagFromList(OutboundBagRow row) {
    if (row.originBranchId != null && row.originBranchId!.isNotEmpty) {
      selectedOriginDepotId.value = row.originBranchId;
    }
    final destId = _destinationIdForRow(row);
    if (destId != null && destId.isNotEmpty) {
      selectedDestDepotId.value = destId;
    }
    if (row.metalSealNo != null && row.metalSealNo!.isNotEmpty) {
      metalSealController.text = row.metalSealNo!;
    }
    final code = row.bagCode ?? row.bagId;
    if (code != null && code.isNotEmpty) {
      bagCodeWorkingController.text = code;
      _loadedBagCode = row.bagCode ?? code;
    }
    _depotContextKey = _buildDepotContextKey();
    sessionScannedRows.clear();
    refreshBagDetailsQuiet();
    Get.back();
  }

  void prefillBaggingReport() {
    if (reportBagCodeController.text.trim().isEmpty) {
      final working = bagCodeWorkingController.text.trim();
      if (working.isNotEmpty) {
        reportBagCodeController.text = working;
      } else {
        final fromDetail = bagDetail.value?.bagCode?.trim();
        if (fromDetail != null && fromDetail.isNotEmpty) {
          reportBagCodeController.text = fromDetail;
        }
      }
    }
  }

  Future<void> baggingReport() async {
    final code = reportBagCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Bagging', 'Bag id is required');
      return;
    }

    isBusy.value = true;
    try {
      final r = await _repo.baggingReport(
        bagCode: code,
      );
      r.when(
        success: (data) {
          final report = BaggingReport.fromDynamic(data);
          baggingReportData.value = report;
        },
        error: _snackServerError,
      );
    } finally {
      isBusy.value = false;
    }
  }

  /// `rebagshipment` — `new_bag_code`, `docket_no`, `user_id` (Postman).
  Future<void> rebagShipment({
    required String newBagCode,
    required String docketNo,
  }) async {
    final docket = docketNo.trim();

    isBusy.value = true;
    try {
      final r = await _repo.rebagShipment(
        newBagId: newBagCode.trim(),
        docketNo: docket,
      );
      r.when(
        success: _snackServerData,
        error: _snackServerError,
      );
    } finally {
      isBusy.value = false;
    }
  }

  void showRebagDialog({String? defaultNewBagCode}) {
    final newBagCtrl = TextEditingController(text: defaultNewBagCode?.trim() ?? '');
    final docketCtrl = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Rebag shipment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newBagCtrl,
              decoration: const InputDecoration(
                labelText: 'New bag code',
                hintText: 'Target bag (new_bag_code)',
              ),
            ),
            TextField(
              controller: docketCtrl,
              decoration: const InputDecoration(
                labelText: 'Docket / shipment ID',
                hintText: 'docket_no',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              await rebagShipment(
                newBagCode: newBagCtrl.text,
                docketNo: docketCtrl.text,
              );
            },
            child: const Text('Rebag'),
          ),
        ],
      ),
    );
  }
}
