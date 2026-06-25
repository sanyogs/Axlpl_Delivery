import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_table_row.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/networking/api_exception.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/bagging_report_pdf_generator.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';

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
  final metalSealFocusNode = FocusNode();
  final metalSealController = TextEditingController();
  final shipmentController = TextEditingController();
  final reportBagCodeController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();

  final selectedOriginDepotId = RxnString();
  final selectedDestDepotId = RxnString();

  String? _lastFetchedShipmentId;
  String? _depotContextKey;
  String? _loadedBagCode;
  String? _lastBagDetailsFetchRef;

  int get bagListTotalCount => bagListAllRows.length;

  int get bagListTotalPages {
    if (bagListAllRows.isEmpty) return 1;
    return (bagListAllRows.length / bagListPageSize).ceil();
  }

  List<OutboundBagRow> get bagListPageRows {
    final rows = bagListAllRows;
    if (rows.isEmpty) return const [];
    final page = bagListPage.value.clamp(1, bagListTotalPages);
    final start = (page - 1) * bagListPageSize;
    if (start >= rows.length) return const [];
    final end = start + bagListPageSize;
    final cappedEnd = end > rows.length ? rows.length : end;
    return rows.sublist(start, cappedEnd);
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

  /// `bag_code` from last successful `getbagdetails` / create — never numeric `bag_id`.
  String get visibleBagCode {
    final detailCode = bagDetail.value?.bagCode?.trim();
    if (detailCode != null && detailCode.isNotEmpty) return detailCode;
    return _loadedBagCode?.trim() ?? '';
  }

  List<BaggingTableRow> get scannedBoxRows {
    final rows = <BaggingTableRow>[];
    final pendingKeys = <String>{};
    final destLabel = _destinationLabel();
    final tableBagCode = visibleBagCode.isEmpty ? null : visibleBagCode;

    for (final r in sessionScannedRows) {
      if (r.sessionKey.isEmpty) continue;
      pendingKeys.add(r.sessionKey);
      rows.add(
        r.bagCode?.trim().isNotEmpty == true
            ? r
            : r.copyWith(bagCode: tableBagCode),
      );
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
      final codeForRows = detail.bagCode?.trim().isNotEmpty == true
          ? detail.bagCode
          : tableBagCode;
      for (final item in detail.items) {
        final key = item.shipmentId?.trim() ?? '';
        if (key.isNotEmpty && pendingKeys.contains(key)) continue;
        rows.add(
          BaggingTableRow.fromBagDetailItem(
            item,
            bagCode: codeForRows,
            destination: savedDestLabel,
            mode: _statusForScannedBoxRow(
              shipmentStatus: item.shipmentStatus,
              bagStatus: detail.manifestStatus,
            ),
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
    metalSealFocusNode.addListener(_onMetalSealFocusChanged);
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

  void _onMetalSealFocusChanged() {
    if (!metalSealFocusNode.hasFocus) {
      onMetalSealFocusLost();
    }
  }

  @override
  void onClose() {
    shipmentFocusNode.removeListener(_onShipmentFocusChanged);
    metalSealFocusNode.removeListener(_onMetalSealFocusChanged);
    shipmentFocusNode.dispose();
    metalSealFocusNode.dispose();
    metalSealController.dispose();
    shipmentController.dispose();
    reportBagCodeController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    super.onClose();
  }

  String? get _originId => selectedOriginDepotId.value?.trim();
  String? get _destId => selectedDestDepotId.value?.trim();

  String? get _workingBagCode {
    final code = _loadedBagCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    return bagDetail.value?.bagCode?.trim();
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

  String? _statusForScannedBoxRow({
    required String? shipmentStatus,
    required String? bagStatus,
  }) {
    final raw = shipmentStatus?.trim();
    if (raw != null && raw.isNotEmpty) {
      if (!raw.toLowerCase().contains('shipment already delivered')) {
        return raw;
      }
    }
    final fallback = bagStatus?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  String _buildDepotContextKey() => '${_originId ?? ''}|${_destId ?? ''}';

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
    resetBaggingSession(clearBagList: true);
  }

  /// Clears the active bag / scan session. Origin and destination depot stay selected.
  void resetBaggingSession({bool clearBagList = false}) {
    metalSealController.clear();
    shipmentController.clear();
    bagDetail.value = null;
    _loadedBagCode = null;
    _lastBagDetailsFetchRef = null;
    sessionScannedRows.clear();
    fetchedShipment.value = null;
    _lastFetchedShipmentId = null;
    fetchStatusMessage.value = '';
    baggingReportData.value = null;
    scrollToScannedTable.value = 0;
    if (clearBagList) {
      bagListAllRows.clear();
      bagListPage.value = 1;
      bagListError.value = '';
    }
  }

  void openBagList() {
    resetBaggingSession();
    Get.toNamed(Routes.OUTBOUND_BAG_LIST);
  }

  void openBaggingReport() {
    resetBaggingSession();
    Get.toNamed(Routes.OUTBOUND_BAGGING_REPORT);
  }

  void returnToFreshBagging() {
    resetBaggingSession();
    Get.back();
  }

  /// Store parsed bag details only — never backfill origin/destination/M-Bag form fields.
  void _storeBagDetail(BagDetail detail, {String? fetchRef}) {
    bagDetail.value = detail;
    final code = detail.bagCode?.trim();
    if (code != null && code.isNotEmpty) {
      _loadedBagCode = code;
    }
    if (fetchRef != null && fetchRef.trim().isNotEmpty) {
      _lastBagDetailsFetchRef = fetchRef.trim();
    }
  }

  void _stageCurrentShipment(HubScanFetchedShipment shipment) {
    final tableBagCode = visibleBagCode.isEmpty ? null : visibleBagCode;
    final row = BaggingTableRow.fromFetchedShipment(
      shipment: shipment,
      scanTyped: shipmentController.text.trim(),
      bagCode: tableBagCode,
      destination: _destinationLabel(),
      saved: false,
    );
    if (row.sessionKey.isEmpty) return;

    final next = List<BaggingTableRow>.from(sessionScannedRows);
    final idx =
        next.indexWhere((r) => r.sessionKey == row.sessionKey && !r.saved);
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

  Future<void> onMetalSealFocusLost() async {
    await loadBagByMetalSeal();
  }

  /// `getbagdetails` — M/Bag No field → `bag_code` query param.
  Future<void> loadBagByMetalSeal() async {
    final ref = metalSealController.text.trim();
    if (ref.isEmpty) {
      _loadedBagCode = null;
      _lastBagDetailsFetchRef = null;
      bagDetail.value = null;
      return;
    }
    isBusy.value = true;
    fetchStatusMessage.value = '';
    try {
      final r = await _repo.fetchBagDetails(ref);
      r.when(
        success: (data) {
          final detail = BagDetail.fromDynamic(
            data,
            requestedBagCode: ref,
          );
          _storeBagDetail(detail, fetchRef: ref);
          sessionScannedRows.clear();
          _snackServerData(data);
        },
        error: (e) {
          fetchStatusMessage.value = e.message.trim();
          _snackServerError(e);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> fetchShipment({String? shipmentOverride}) async {
    final connote = (shipmentOverride ?? shipmentController.text).trim();
    if (connote.isEmpty) return;
    if (_looksLikeBagReference(connote)) {
      metalSealController.text = connote;
      await loadBagByMetalSeal();
      if (bagDetail.value != null) {
        shipmentController.clear();
        fetchStatusMessage.value = 'Bag loaded. Scan shipment ID to add boxes.';
      }
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

  Future<void> onMetalSealScanned(String value) async {
    if (value.trim().isEmpty || value == '-1') return;
    metalSealController.text = value.trim();
    await loadBagByMetalSeal();
  }

  bool _looksLikeBagReference(String value) {
    final ref = value.trim();
    if (ref.isEmpty) return false;
    final upper = ref.toUpperCase();
    return OutboundApiParams.looksLikeBagCode(ref) ||
        upper.startsWith('G') ||
        upper.startsWith('MSEAL');
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
          await loadBagByMetalSeal();
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
          } else {
            _markPendingRowsSaved(pending, bagCode: bagCode);
            scrollToScannedTable.value++;
          }
        } else if (pending.isEmpty) {
          ok = true;
        } else {
          ok = false;
        }
      } else {
        final ids = pending
            .map((r) => r.docketForApi)
            .where((s) => s.isNotEmpty)
            .toList();

        final r = await _repo.createBag(
          originBranchId: origin,
          destinationBranchId: dest,
          metalSealNo: metalSeal,
          shipmentIdsCsv: OutboundApiParams.shipmentIdsCsv(ids),
        );
        var created = false;
        r.when(
          success: (data) {
            created = true;
            savedCount = ids.length;
            final result = OutboundMutationResult.fromDynamic(data);
            final ref = result.effectiveBagRef;
            if (ref != null && ref.isNotEmpty) {
              _loadedBagCode = ref;
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
        } else {
          _markPendingRowsSaved(pending, bagCode: _workingBagCode);
          scrollToScannedTable.value++;
        }
      }
    } finally {
      isBusy.value = false;
    }
    return ok;
  }

  void _markPendingRowsSaved(
    List<BaggingTableRow> pending, {
    String? bagCode,
  }) {
    final savedBagCode = bagCode?.trim();
    final pendingKeys = pending.map((r) => r.sessionKey).toSet();
    sessionScannedRows.assignAll(
      sessionScannedRows
          .map(
            (r) => pendingKeys.contains(r.sessionKey)
                ? r.copyWith(
                    bagCode:
                        savedBagCode?.isEmpty == false ? savedBagCode : null,
                    saved: true,
                  )
                : r,
          )
          .toList(growable: false),
    );
  }

  String? get _bagDetailsFetchRef {
    final code = _workingBagCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    final seal = metalSealController.text.trim();
    if (seal.isNotEmpty) return seal;
    return _lastBagDetailsFetchRef;
  }

  Future<bool> refreshBagDetailsQuiet() async {
    final ref = _bagDetailsFetchRef;
    if (ref == null || ref.isEmpty) return false;
    final r = await _repo.fetchBagDetails(ref);
    return r.when(
      success: (data) {
        final detail = BagDetail.fromDynamic(
          data,
          requestedBagCode: ref,
        );
        _storeBagDetail(detail, fetchRef: ref);
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
    if (origin == null ||
        origin.isEmpty ||
        bagCode == null ||
        bagCode.isEmpty) {
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
      final msg = _repo.lastMessage.trim();
      if (msg.isNotEmpty) {
        bagListError.value = msg;
        return false;
      }
      return true;
    } catch (e) {
      bagListError.value = e.toString();
      return false;
    } finally {
      isBagListLoading.value = false;
    }
  }

  void openBagDetailsFromList(OutboundBagRow row) {
    final fetchRef = _bagRefFromRow(row);
    if (fetchRef == null) {
      Get.snackbar('Bagging', 'Bag reference is required.');
      return;
    }
    // View-only — never loads this bag into the bagging edit session.
    Get.toNamed(
      Routes.OUTBOUND_BAGGING_DETAILS,
      arguments: {'bagRef': fetchRef},
    );
  }

  String? _bagRefFromRow(OutboundBagRow row) {
    final code = row.bagCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    final seal = row.metalSealNo?.trim();
    if (seal != null && seal.isNotEmpty) return seal;
    return null;
  }

  /// Loads bag into the edit session — only for **Add More** from bag details.
  Future<void> openBagForEditing(
    BagDetail detail, {
    String? fetchRef,
  }) async {
    final ref = fetchRef?.trim().isNotEmpty == true
        ? fetchRef!.trim()
        : detail.bagCode?.trim().isNotEmpty == true
            ? detail.bagCode!.trim()
            : detail.metalSealNo?.trim();
    if (ref != null && ref.isNotEmpty) {
      _lastBagDetailsFetchRef = ref;
      if (detail.bagCode?.trim().isNotEmpty == true) {
        _loadedBagCode = detail.bagCode!.trim();
      }
      final seal = detail.metalSealNo?.trim();
      if (seal != null && seal.isNotEmpty) {
        metalSealController.text = seal;
      }
    }
    _storeBagDetail(detail, fetchRef: ref);
    sessionScannedRows.clear();
    await refreshBagDetailsQuiet();
  }

  void prefillBaggingReport() {
    if (reportBagCodeController.text.trim().isEmpty) {
      final fromDetail = visibleBagCode.trim();
      if (fromDetail.isNotEmpty) {
        reportBagCodeController.text = fromDetail;
      }
    }
  }

  Future<String?> _messengerDisplayName() async {
    final user = await LocalStorage().getUserLocalData();
    return user?.messangerdetail?.name?.trim();
  }

  Future<APIResponse<dynamic>> _fetchBaggingReportForRef(String ref) async {
    final trimmed = ref.trim();
    final first = await _repo.baggingReport(bagCode: trimmed);
    final firstOk = _baggingReportHasContent(first);
    if (firstOk) return first;

    if (OutboundApiParams.looksLikeBagCode(trimmed)) {
      return first;
    }

    final detailR = await _repo.fetchBagDetails(trimmed);
    BagDetail? detail;
    detailR.when(
      success: (data) =>
          detail = BagDetail.fromDynamic(data, requestedBagCode: trimmed),
      error: (_) {},
    );
    final resolved = detail?.bagCode?.trim();
    if (resolved != null &&
        resolved.isNotEmpty &&
        resolved.toLowerCase() != trimmed.toLowerCase()) {
      final second = await _repo.baggingReport(bagCode: resolved);
      if (_baggingReportHasContent(second)) return second;
    }
    return first;
  }

  bool _baggingReportHasContent(APIResponse<dynamic> response) {
    var ok = false;
    response.when(
      success: (data) {
        final report = BaggingReport.fromDynamic(data);
        ok = (report.bagCode?.trim().isNotEmpty == true) || report.items.isNotEmpty;
      },
      error: (_) => ok = false,
    );
    return ok;
  }

  Future<void> printBaggingReport() async {
    final code = reportBagCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Bagging', 'Bagging number is required.');
      return;
    }
    await _printBaggingChallan(code);
  }

  Future<void> printBagChallanFromRow(OutboundBagRow row) async {
    final ref = _bagRefFromRow(row);
    if (ref == null) {
      Get.snackbar('Bagging', 'Bag reference is required.');
      return;
    }
    await _printBaggingChallan(ref);
  }

  Future<void> _printBaggingChallan(String code) async {
    final ref = code.trim();
    if (ref.isEmpty) {
      Get.snackbar('Bagging', 'Bagging number is required.');
      return;
    }

    isBusy.value = true;
    try {
      final r = await _fetchBaggingReportForRef(ref);
      dynamic data;
      var failed = false;
      r.when(
        success: (value) => data = value,
        error: (e) {
          failed = true;
          _snackServerError(e);
        },
      );
      if (failed || data == null) return;

      final report = BaggingReport.fromDynamic(data);
      if ((report.bagCode == null || report.bagCode!.isEmpty) &&
          report.items.isEmpty) {
        Get.snackbar('Bagging', 'No bagging report data returned.');
        return;
      }
      baggingReportData.value = report;
      final messengerName = await _messengerDisplayName();
      final createdBy = report.createdByLabel(messengerName);
      final path = await BaggingReportPdfGenerator.save(
        report: report,
        createdByDisplay: createdBy,
      );
      final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim();
      final open = await OpenFile.open(path);
      if (open.type != ResultType.done) {
        Get.snackbar(
          'Bagging',
          msg?.isNotEmpty == true
              ? '$msg\nSaved: $path'
              : 'PDF saved: $path',
        );
        return;
      }
      Get.snackbar(
        'Bagging',
        msg?.isNotEmpty == true ? msg! : 'Bagging report PDF generated.',
      );
    } finally {
      isBusy.value = false;
    }
  }

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
    final newBagCtrl =
        TextEditingController(text: defaultNewBagCode?.trim() ?? '');
    final docketCtrl = TextEditingController();
    Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            child: OutboundAdminSection(
              title: OutboundLabels.btnRebag,
              children: [
                Text(
                  'Move a shipment from this bag into another bag.',
                  style: themes.fontSize14_400.copyWith(
                    color: themes.grayColor,
                  ),
                ),
                OutboundLabeledFieldRow(
                  label: OutboundLabels.newBagCode,
                  required: true,
                  child: OutboundAdminInput(
                    controller: newBagCtrl,
                    hintText: OutboundLabels.newBagCode,
                  ),
                ),
                OutboundLabeledFieldRow(
                  label: OutboundLabels.docketNo,
                  required: true,
                  child: OutboundAdminInput(
                    controller: docketCtrl,
                    hintText: OutboundLabels.docketNo,
                  ),
                ),
                OutboundButtonRow(
                  start: OutboundSecondaryButton(
                    label: OutboundLabels.btnCancel,
                    onPressed: () => Get.back(),
                  ),
                  end: OutboundPrimaryButtonCompact(
                    title: OutboundLabels.btnRebag,
                    onPressed: () async {
                      final newBag = newBagCtrl.text.trim();
                      final docket = docketCtrl.text.trim();
                      if (newBag.isEmpty || docket.isEmpty) {
                        Get.snackbar(
                          'Bagging',
                          'New bag code and docket are required.',
                        );
                        return;
                      }
                      Get.back();
                      await rebagShipment(
                        newBagCode: newBag,
                        docketNo: docket,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    ).whenComplete(() {
      newBagCtrl.dispose();
      docketCtrl.dispose();
    });
  }
}
