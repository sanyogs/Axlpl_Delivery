import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_table_row.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/outbound_bagging_validation.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();

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
    if (detail != null && !_bagMatchesSelectedDepots(detail)) {
      return rows;
    }

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
    reportStartController.dispose();
    reportEndController.dispose();
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

  bool _validateDepotsForAction(String action) {
    final err = OutboundBaggingValidation.validateDepots(
      originBranchId: _originId,
      destinationBranchId: _destId,
    );
    if (err != null) {
      Get.snackbar('Bagging', '$err before $action');
      return false;
    }
    return true;
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

  bool _bagMatchesSelectedDepots(BagDetail? detail) {
    if (detail == null) return true;
    final origin = _originId;
    final dest = _destId;
    if (origin != null &&
        origin.isNotEmpty &&
        detail.originBranchId != null &&
        detail.originBranchId!.isNotEmpty &&
        detail.originBranchId != origin) {
      return false;
    }
    if (dest != null && dest.isNotEmpty) {
      final bagDest = detail.destinationSectorId ?? detail.destinationBranchId;
      if (bagDest != null && bagDest.isNotEmpty && bagDest != dest) {
        return false;
      }
    }
    return true;
  }

  bool _canStageScan() {
    if (!_validateDepotsForAction('scanning')) return false;
    final sealErr = OutboundBaggingValidation.validateMetalSealNo(
      metalSealController.text,
    );
    if (sealErr != null) {
      Get.snackbar('Bagging', sealErr);
      return false;
    }
    return true;
  }

  void _stageCurrentShipment(HubScanFetchedShipment shipment) {
    if (!_canStageScan()) return;

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

  void _clearShipmentFieldOnly() {
    shipmentController.clear();
    fetchedShipment.value = null;
    _lastFetchedShipmentId = null;
    fetchStatusMessage.value = '';
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
    final err = OutboundBaggingValidation.validateBagCode(code);
    if (err != null) {
      Get.snackbar('Bagging', err);
      return;
    }
    if (!_validateDepotsForAction('load bag')) return;

    isBusy.value = true;
    try {
      final r = await _repo.fetchBagDetails(code);
      r.when(
        success: (data) {
          final detail = BagDetail.fromDynamic(data);
          if (detail.bagCode == null || detail.bagCode!.isEmpty) {
            Get.snackbar('Bagging', 'Bag not found');
            return;
          }
          if (!_bagMatchesSelectedDepots(detail)) {
            Get.snackbar(
              'Bagging',
              'Bag does not match selected origin/destination depots',
            );
            return;
          }
          bagDetail.value = detail;
          _applyBagDetailToSelection(detail);
          sessionScannedRows.clear();
          Get.snackbar('Bagging', 'Bag ${detail.bagCode} loaded');
        },
        error: (e) {
          if (e.message.trim().isNotEmpty) {
            Get.snackbar('Bagging', e.message.trim());
          }
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> fetchShipment({String? shipmentOverride}) async {
    if (!_validateDepotsForAction('scan')) return;
    final connote = (shipmentOverride ?? shipmentController.text).trim();
    final err = OutboundBaggingValidation.validateShipmentDocket(connote);
    if (err != null) {
      Get.snackbar('Bagging', err);
      return;
    }
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
    if (!_validateDepotsForAction('Confirm')) return;

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

    final bagCode = _workingBagCode;
    final bagErr = OutboundBaggingValidation.validateBagCode(
      bagCode,
      required: true,
    );
    if (bagErr != null) {
      shipmentFocusNode.unfocus();
      _clearShipmentFieldOnly();
      Get.snackbar('Bagging', bagErr);
      return;
    }

    await refreshBagDetailsQuiet();
    final detail = bagDetail.value;
    if (detail != null && !_bagMatchesSelectedDepots(detail)) {
      Get.snackbar(
        'Bagging',
        'Bag does not match selected '
        '${_branchList.displayLabelForId(_originId)} → '
        '${_branchList.displayLabelForId(_destId)}',
      );
      return;
    }

    isBusy.value = true;
    try {
      final r = await _repo.lockBag(bagCode!);
      var locked = false;
      r.when(
        success: (data) {
          locked = true;
          final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
          Get.snackbar(
            'Bagging',
            msg.isNotEmpty ? msg : 'Bag locked — ready for manifest',
          );
        },
        error: (e) {
          if (e.message.trim().isNotEmpty) {
            Get.snackbar('Bagging', e.message.trim());
          }
        },
      );
      if (locked) {
        _resetForNewBag(keepDepots: true);
      }
    } finally {
      isBusy.value = false;
    }
  }

  void _resetForNewBag({bool keepDepots = false}) {
    sessionScannedRows.clear();
    bagDetail.value = null;
    bagCodeWorkingController.clear();
    _loadedBagCode = null;
    metalSealController.clear();
    shipmentController.clear();
    fetchedShipment.value = null;
    _lastFetchedShipmentId = null;
    fetchStatusMessage.value = '';
    if (!keepDepots) {
      selectedOriginDepotId.value = null;
      selectedDestDepotId.value = null;
      _depotContextKey = _buildDepotContextKey();
    }
  }

  Future<void> saveBagging() async {
    await _savePendingShipments();
  }

  bool _isExistingBagSession() {
    final code = _workingBagCode;
    return code != null &&
        OutboundApiParams.looksLikeBagCode(code) &&
        OutboundBaggingValidation.validateBagCode(code) == null;
  }

  Future<bool> _savePendingShipments() async {
    final depotErr = OutboundBaggingValidation.validateDepots(
      originBranchId: _originId,
      destinationBranchId: _destId,
    );
    if (depotErr != null) {
      Get.snackbar('Bagging', depotErr);
      return false;
    }

    final origin = _originId!;
    final dest = _destId!;

    final sealErr = OutboundBaggingValidation.validateMetalSealNo(
      metalSealController.text,
    );
    if (sealErr != null) {
      Get.snackbar('Bagging', sealErr);
      return false;
    }
    final metalSeal = metalSealController.text.trim();

    final pending =
        sessionScannedRows.where((r) => !r.saved).toList(growable: false);

    if (pending.isEmpty && !_isExistingBagSession()) {
      Get.snackbar('Bagging', 'Scan at least one shipment before Save');
      return false;
    }

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
          final docketErr = OutboundBaggingValidation.validateShipmentDocket(docket);
          if (docketErr != null) {
            Get.snackbar('Bagging', docketErr);
            ok = false;
            break;
          }

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
              final msg = OutboundUiFeedback.serverMessageFromData(data) ?? '';
              if (msg.isNotEmpty) Get.snackbar('Bagging', msg);
            },
            error: (e) {
              ok = false;
              final msg = e.message.trim();
              if (msg.isNotEmpty) Get.snackbar('Bagging', '$docket: $msg');
            },
          );
          if (!rowOk) break;
        }
        if (savedCount > 0) {
          sessionScannedRows.clear();
          await refreshBagDetailsQuiet();
          Get.snackbar(
            'Bagging',
            savedCount == pending.length
                ? 'Shipment(s) added to bag.'
                : '$savedCount of ${pending.length} added.',
          );
        } else if (pending.isEmpty) {
          Get.snackbar('Bagging', 'Bag loaded — scan shipments to add');
          ok = true;
        } else {
          ok = false;
        }
      } else {
        final ids = pending.map((r) => r.docketForApi).where((s) => s.isNotEmpty).toList();
        if (ids.isEmpty) {
          Get.snackbar('Bagging', 'Scan at least one shipment before Save');
          return false;
        }
        for (final id in ids) {
          final docketErr = OutboundBaggingValidation.validateShipmentDocket(id);
          if (docketErr != null) {
            Get.snackbar('Bagging', docketErr);
            return false;
          }
        }

        final customBagCode = _workingBagCode;
        String? createBagCode;
        if (customBagCode != null && customBagCode.isNotEmpty) {
          final codeErr = OutboundBaggingValidation.validateBagCode(customBagCode);
          if (codeErr != null) {
            Get.snackbar('Bagging', codeErr);
            return false;
          }
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
            final msg = OutboundUiFeedback.serverMessageFromData(data) ?? '';
            if (msg.isNotEmpty) Get.snackbar('Bagging', msg);
          },
          error: (e) {
            ok = false;
            if (e.message.trim().isNotEmpty) {
              Get.snackbar('Bagging', e.message.trim());
            }
          },
        );
        if (!created) return false;
        sessionScannedRows.clear();
        await refreshBagDetailsQuiet();
      }
    } finally {
      isBusy.value = false;
    }
    return ok;
  }

  Future<void> refreshBagDetailsQuiet() async {
    final code = _workingBagCode;
    if (code == null) return;
    final err = OutboundBaggingValidation.validateBagCode(code);
    if (err != null) return;

    final r = await _repo.fetchBagDetails(code);
    r.when(
      success: (data) {
        final detail = BagDetail.fromDynamic(data);
        bagDetail.value = detail;
        _applyBagDetailToSelection(detail);
      },
      error: (_) {},
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
    final bagErr = OutboundBaggingValidation.validateBagCode(bagCode, required: true);
    if (origin == null || origin.isEmpty || bagErr != null) {
      Get.snackbar('Bagging', bagErr ?? 'Cannot remove — origin depot missing');
      return;
    }

    final docketErr = OutboundBaggingValidation.validateShipmentDocket(row.docketForApi);
    if (docketErr != null) {
      Get.snackbar('Bagging', docketErr);
      return;
    }

    _removeShipmentFromBag(
      bagCode: bagCode!,
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
          Get.snackbar('Bagging', 'Shipment removed from bag');
          await refreshBagDetailsQuiet();
        },
        error: (e) {
          if (e.message.trim().isNotEmpty) {
            Get.snackbar('Bagging', e.message.trim());
          }
        },
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
    final branchErr = OutboundBaggingValidation.validateOriginBranchId(_originId);
    if (branchErr != null) {
      bagListError.value = branchErr;
      return false;
    }
    final destErr = OutboundBaggingValidation.validateDestinationBranchId(_destId);
    if (destErr != null) {
      bagListError.value = '$destErr (set on bagging screen first)';
      return false;
    }

    isBagListLoading.value = true;
    bagListError.value = '';
    bagListAllRows.clear();
    bagListPage.value = 1;
    try {
      final rows = await _repo.listBags(branchId: _originId!);
      bagListAllRows.assignAll(rows);
      final filtered = bagListFilteredRows;
      if (filtered.isEmpty) {
        final destLabel = _branchList.displayLabelForId(_destId);
        bagListError.value = rows.isEmpty
            ? (_repo.lastMessage.trim().isNotEmpty
                ? _repo.lastMessage
                : 'No bags found for this origin depot.')
            : 'No bags for destination $destLabel at this origin.';
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
    Get.snackbar('Bagging', 'Bag loaded — scan more shipments or Confirm to lock');
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
    if (reportStartController.text.trim().isEmpty) {
      final end = DateTime.now();
      final start = end.subtract(const Duration(days: 30));
      final fmt = DateFormat('yyyy-MM-dd');
      reportStartController.text = fmt.format(start);
      reportEndController.text = fmt.format(end);
    }
  }

  Future<void> baggingReport() async {
    final code = reportBagCodeController.text.trim();
    final start = reportStartController.text.trim();
    final end = reportEndController.text.trim();

    final err = OutboundBaggingValidation.validateBaggingReportRequest(
      bagCode: code,
      startDate: start,
      endDate: end,
    );
    if (err != null) {
      Get.snackbar('Bagging', err);
      return;
    }

    isBusy.value = true;
    try {
      final r = await _repo.baggingReport(
        bagCode: code.isNotEmpty ? code : null,
        startDate: code.isEmpty ? start : (start.isNotEmpty ? start : null),
        endDate: code.isEmpty ? end : (end.isNotEmpty ? end : null),
      );
      r.when(
        success: (data) {
          final report = BaggingReport.fromDynamic(data);
          baggingReportData.value = report;
          if (report.items.isEmpty &&
              report.bagCode == null &&
              code.isNotEmpty) {
            Get.snackbar('Bagging', 'No report data for this bag code');
          }
        },
        error: (e) {
          if (e.message.trim().isNotEmpty) {
            Get.snackbar('Bagging', e.message.trim());
          }
        },
      );
    } finally {
      isBusy.value = false;
    }
  }
}
