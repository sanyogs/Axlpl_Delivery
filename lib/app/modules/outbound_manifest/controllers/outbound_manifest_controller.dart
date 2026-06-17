import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_session_models.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_manifest_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/networking/api_exception.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundManifestController extends GetxController {
  OutboundManifestController({
    OutboundRepository? repo,
    OutboundBranchListController? branchList,
  })  : _repo = repo ?? Get.find<OutboundRepository>(),
        _branchList = branchList ?? Get.find<OutboundBranchListController>();

  final OutboundRepository _repo;
  final OutboundBranchListController _branchList;

  final isBusy = false.obs;
  final isManifestListLoading = false.obs;
  final manifestListError = ''.obs;
  final fetchStatusMessage = ''.obs;
  final lastResponseText = ''.obs;

  final sessionBags = <ManifestBagSessionRow>[].obs;
  final manifestListAllRows = <OutboundManifestRow>[].obs;
  final manifestListPage = 1.obs;
  final manifestDetail = Rxn<ManifestDetail>();
  final manifestReportData = Rxn<ManifestReport>();
  final printManifestDetail = Rxn<ManifestDetail>();

  final selectedOriginDepotId = RxnString();
  final selectedDestDepotId = RxnString();
  final selectedTransportMode = OutboundLabels.modeSurface.obs;

  final bagScanController = TextEditingController();
  final bagScanFocusNode = FocusNode();
  final manifestCodeController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();
  final reportManifestCodeController = TextEditingController();

  final connoteCountController = TextEditingController();
  final boxCountController = TextEditingController();
  final bagsSelectedController = TextEditingController();
  final connoteWeightController = TextEditingController();
  final conVolWeightController = TextEditingController();
  final bagWeightController = TextEditingController();

  static const manifestListPageSize = 25;
  String? _depotContextKey;

  List<Map<String, dynamic>> get listRows =>
      manifestListAllRows.map((r) => r.asMap).toList();

  int get manifestListTotalCount => manifestListAllRows.length;

  int get manifestListTotalPages {
    if (manifestListAllRows.isEmpty) return 1;
    return (manifestListAllRows.length / manifestListPageSize).ceil();
  }

  List<OutboundManifestRow> get manifestListPageRows {
    final rows = manifestListAllRows;
    if (rows.isEmpty) return const [];
    final page = manifestListPage.value.clamp(1, manifestListTotalPages);
    final start = (page - 1) * manifestListPageSize;
    if (start >= rows.length) return const [];
    final end = start + manifestListPageSize;
    final cappedEnd = end > rows.length ? rows.length : end;
    return rows.sublist(start, cappedEnd);
  }

  int get manifestListRowNumberOffset =>
      (manifestListPage.value.clamp(1, manifestListTotalPages) - 1) *
      manifestListPageSize;

  String get manifestListRangeLabel {
    final total = manifestListTotalCount;
    if (total == 0) return '0 records';
    final page = manifestListPage.value.clamp(1, manifestListTotalPages);
    final start = (page - 1) * manifestListPageSize + 1;
    final end = start + manifestListPageRows.length - 1;
    return '$start–$end of $total';
  }

  String get selectedDepotSummary {
    final origin = _branchList.displayLabelForId(_originId);
    final dest = _branchList.displayLabelForId(_destId);
    if (_originId == null && _destId == null) return '';
    return 'Origin: $origin → Destination: $dest';
  }

  List<ManifestShipmentSessionRow> get shipmentLines {
    final rows = <ManifestShipmentSessionRow>[];
    final seen = <String>{};
    for (final bag in sessionBags) {
      final items = bag.detail.items;
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final row = ManifestShipmentSessionRow.fromBagDetailItem(
          item,
          bagCode: bag.bagCode,
          originLabel: bag.originLabel,
        );
        final key = row.sessionKey;
        if (key.isEmpty || seen.contains(key)) continue;
        seen.add(key);
        rows.add(row);
      }
    }
    return rows;
  }

  String? get _originId => selectedOriginDepotId.value?.trim();
  String? get _destId => selectedDestDepotId.value?.trim();

  @override
  void onInit() {
    super.onInit();
    bagScanFocusNode.addListener(_onBagScanFocusChanged);
    _depotContextKey = _buildDepotContextKey();
    _refreshSummaryFields();
  }

  void _onBagScanFocusChanged() {
    if (!bagScanFocusNode.hasFocus) {
      onBagScanFocusLost();
    }
  }

  @override
  void onClose() {
    bagScanFocusNode.removeListener(_onBagScanFocusChanged);
    bagScanFocusNode.dispose();
    bagScanController.dispose();
    manifestCodeController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    reportManifestCodeController.dispose();
    connoteCountController.dispose();
    boxCountController.dispose();
    bagsSelectedController.dispose();
    connoteWeightController.dispose();
    conVolWeightController.dispose();
    bagWeightController.dispose();
    super.onClose();
  }

  String _buildDepotContextKey() => '${_originId ?? ''}|${_destId ?? ''}';

  void _snackServerData(dynamic data) {
    final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim() ?? '';
    if (msg.isNotEmpty) Get.snackbar('Manifest', msg);
  }

  void _snackServerError(AppException e) {
    final msg = e.message.trim();
    if (msg.isNotEmpty) Get.snackbar('Manifest', msg);
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

  void onTransportModeChanged(String mode) {
    selectedTransportMode.value = mode;
  }

  void _onDepotContextChanged() {
    final next = _buildDepotContextKey();
    if (_depotContextKey == next) return;
    _depotContextKey = next;
    sessionBags.clear();
    manifestListAllRows.clear();
    manifestListPage.value = 1;
    manifestListError.value = '';
    fetchStatusMessage.value = '';
    bagScanController.clear();
    _refreshSummaryFields();
  }

  void _refreshSummaryFields() {
    final lines = shipmentLines;
    final connotes = <String>{};
    for (final line in lines) {
      final id = line.consignmentNo?.trim();
      if (id != null && id.isNotEmpty) connotes.add(id);
    }

    var boxCount = 0;
    for (final line in lines) {
      final pcs = int.tryParse(line.pcs?.trim() ?? '') ?? 1;
      boxCount += pcs > 0 ? pcs : 1;
    }
    if (boxCount == 0 && lines.isNotEmpty) boxCount = lines.length;

    double conGross = 0;
    double conVol = 0;
    var hasGross = false;
    var hasVol = false;
    for (final line in lines) {
      final g = double.tryParse(line.grossWeight?.trim() ?? '');
      if (g != null) {
        conGross += g;
        hasGross = true;
      }
      final v = double.tryParse(line.volumetricWeight?.trim() ?? '');
      if (v != null) {
        conVol += v;
        hasVol = true;
      }
    }

    double bagWt = 0;
    var hasBagWt = false;
    for (final bag in sessionBags) {
      final w = double.tryParse(bag.weight?.trim() ?? '');
      if (w != null) {
        bagWt += w;
        hasBagWt = true;
      }
    }

    connoteCountController.text = '${connotes.length}';
    boxCountController.text = '$boxCount';
    bagsSelectedController.text = '${sessionBags.length}';
    connoteWeightController.text = hasGross ? _formatWeight(conGross) : '0';
    conVolWeightController.text = hasVol ? _formatWeight(conVol) : '0';
    bagWeightController.text = hasBagWt ? _formatWeight(bagWt) : '0';
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  Future<void> onBagScanFocusLost() async {
    final code = bagScanController.text.trim();
    if (code.isEmpty) return;
    await scanBag(code);
  }

  Future<void> onBagScanned(String value) async {
    if (value.trim().isEmpty || value == '-1') return;
    bagScanController.text = value.trim();
    await scanBag(value.trim());
  }

  Future<void> scanBag(String code) async {
    final bagCode = code.trim();
    if (bagCode.isEmpty) return;

    if (sessionBags.any((b) => b.bagCode == bagCode)) {
      fetchStatusMessage.value = 'Bag $bagCode is already in this session.';
      return;
    }

    isBusy.value = true;
    fetchStatusMessage.value = '';
    try {
      final r = await _repo.fetchBagDetails(bagCode);
      await r.when(
        success: (data) async {
          final detail = BagDetail.fromDynamic(
            data,
            requestedBagCode: bagCode,
          );
          final resolvedCode = detail.bagCode?.trim() ?? bagCode;
          if (sessionBags.any((b) => b.bagCode == resolvedCode)) {
            fetchStatusMessage.value =
                'Bag $resolvedCode is already in this session.';
            return;
          }

          final canAutoFillDepot = sessionBags.isEmpty;
          if (detail.originBranchId != null &&
              detail.originBranchId!.isNotEmpty &&
              (canAutoFillDepot || _originId == null)) {
            selectedOriginDepotId.value = detail.originBranchId;
          }
          if (detail.destinationSectorId != null &&
              detail.destinationSectorId!.isNotEmpty &&
              (canAutoFillDepot || _destId == null)) {
            selectedDestDepotId.value = detail.destinationSectorId;
          }
          _depotContextKey = _buildDepotContextKey();

          final row = ManifestBagSessionRow.fromBagDetail(
            detail,
            branchLabel: _branchList.displayLabelForId,
            rawData: data,
          );
          if (row.bagCode.isEmpty) {
            fetchStatusMessage.value = 'Bag code not found in response.';
            return;
          }

          sessionBags.add(row);
          _refreshSummaryFields();
          bagScanController.clear();
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

  void removeSessionBag(ManifestBagSessionRow row) {
    sessionBags.removeWhere((b) => b.bagCode == row.bagCode);
    _refreshSummaryFields();
  }

  String get _sessionBagCodesCsv =>
      sessionBags.map((b) => b.bagCode).join(',');

  Future<void> createManifest() async {
    final origin = _originId ?? '';
    final dest = _destId ?? '';
    final bagCodes = _sessionBagCodesCsv;

    if (bagCodes.isEmpty) {
      Get.snackbar('Manifest', 'Scan at least one M/Bag.');
      return;
    }
    if (origin.isEmpty || dest.isEmpty) {
      Get.snackbar('Manifest', 'Select origin and destination depot.');
      return;
    }

    isBusy.value = true;
    try {
      final r = await _repo.createManifest(
        bagIdsCommaSeparated: bagCodes,
        originBranchId: origin,
        destinationBranchId: dest,
        transportMode: selectedTransportMode.value,
      );
      r.when(
        success: (data) {
          lastResponseText.value = '';
          final result = OutboundMutationResult.fromDynamic(data);
          final code = result.effectiveManifestRef;
          if (code != null && code.isNotEmpty) {
            manifestCodeController.text = code;
          }
          sessionBags.clear();
          bagScanController.clear();
          fetchStatusMessage.value = '';
          _refreshSummaryFields();
          _snackServerData(data);
        },
        error: (e) {
          lastResponseText.value = e.message;
          _snackServerError(e);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<bool> loadManifestList() async {
    isManifestListLoading.value = true;
    manifestListError.value = '';
    manifestListAllRows.clear();
    manifestListPage.value = 1;
    try {
      final rows = await _repo.listManifests(branchId: _originId ?? '');
      manifestListAllRows.assignAll(rows);
      final msg = _repo.lastMessage.trim();
      if (msg.isNotEmpty) {
        manifestListError.value = msg;
        return false;
      }
      return true;
    } catch (e) {
      manifestListError.value = e.toString();
      return false;
    } finally {
      isManifestListLoading.value = false;
    }
  }

  void manifestListGoToPage(int page) {
    manifestListPage.value = page.clamp(1, manifestListTotalPages);
  }

  void manifestListNextPage() {
    if (manifestListPage.value < manifestListTotalPages) {
      manifestListPage.value++;
    }
  }

  void manifestListPreviousPage() {
    if (manifestListPage.value > 1) manifestListPage.value--;
  }

  void applyManifestIdFromListRow(Map<String, dynamic> row) {
    applyManifestFromRow(OutboundManifestRow.fromJson(row));
  }

  void applyManifestFromRow(OutboundManifestRow row) {
    final code = row.manifestNo ?? row.manifestId;
    if (code == null || code.isEmpty) return;
    manifestCodeController.text = code;
    if (row.originBranch != null && row.originBranch!.isNotEmpty) {
      selectedOriginDepotId.value = row.originBranch;
    }
    if (row.destinationBranch != null && row.destinationBranch!.isNotEmpty) {
      selectedDestDepotId.value = row.destinationBranch;
    }
    _depotContextKey = _buildDepotContextKey();
    Get.back();
  }

  Future<void> getManifestDetails({String? manifestCode}) async {
    final code = (manifestCode ?? manifestCodeController.text).trim();
    if (code.isEmpty) {
      Get.snackbar('Manifest', 'Manifest number is required.');
      return;
    }
    manifestCodeController.text = code;
    isBusy.value = true;
    manifestDetail.value = null;
    try {
      final r = await _repo.fetchManifestDetails(code);
      r.when(
        success: (data) {
          final detail = ManifestDetail.fromDynamic(data);
          manifestDetail.value = detail;
          lastResponseText.value = '';
          _snackServerData(data);
        },
        error: (e) {
          lastResponseText.value = e.message;
          _snackServerError(e);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> printManifestData({String? manifestCode}) async {
    final code = (manifestCode ?? manifestCodeController.text).trim();
    if (code.isEmpty) {
      Get.snackbar('Manifest', 'Manifest number is required.');
      return;
    }
    manifestCodeController.text = code;
    isBusy.value = true;
    try {
      final r = await _repo.printManifestData(code);
      r.when(
        success: (data) {
          final detail = ManifestDetail.fromDynamic(data);
          printManifestDetail.value = detail;
          manifestDetail.value = detail;
          lastResponseText.value = '';
          _snackServerData(data);
        },
        error: (e) {
          lastResponseText.value = e.message;
          _snackServerError(e);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  void prefillManifestReport() {
    if (reportManifestCodeController.text.trim().isEmpty) {
      final working = manifestCodeController.text.trim();
      if (working.isNotEmpty) {
        reportManifestCodeController.text = working;
      }
    }
  }

  Future<void> manifestReport() async {
    isBusy.value = true;
    try {
      final r = await _repo.manifestReport(
        startDate: reportStartController.text.trim(),
        endDate: reportEndController.text.trim(),
        manifestNo: reportManifestCodeController.text.trim().isEmpty
            ? null
            : reportManifestCodeController.text.trim(),
      );
      r.when(
        success: (data) {
          final report = ManifestReport.fromDynamic(data);
          manifestReportData.value = report;
          lastResponseText.value = '';
          _snackServerData(data);
        },
        error: (e) {
          lastResponseText.value = e.message;
          _snackServerError(e);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  void openManifestDetailPage() {
    final code = manifestCodeController.text.trim();
    Get.toNamed(
      Routes.OUTBOUND_REMOTE_DETAIL,
      arguments: {'kind': 'manifest', 'id': code},
    );
  }
}
