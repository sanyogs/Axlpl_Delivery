import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/pickup_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_api_envelope.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_session_models.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_repository_retry.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundSectorPickupController extends GetxController {
  OutboundSectorPickupController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final isListLoading = false.obs;
  final pickupRows = <SectorPickupRow>[].obs;
  final scannedRows = <SectorPickupScannedRow>[].obs;
  final missingRows = <SectorPickupMissingRow>[].obs;
  final scrollToScannedTable = 0.obs;

  final pickupIdController = TextEditingController();
  final mawbController = TextEditingController();
  final originHubController = TextEditingController();
  final destHubController = TextEditingController();
  final pickupDateController = TextEditingController();
  final pickupTimeController = TextEditingController();
  final pickedByController = TextEditingController();
  final flightInfoController = TextEditingController();
  final bagSealController = TextEditingController();
  final docketController = TextEditingController();
  final remarksController = TextEditingController();

  final docketFocusNode = FocusNode();
  final bagSealFocusNode = FocusNode();

  String? _pendingBagSeal;

  int get manifestedCount =>
      scannedRows.length + missingRows.length;

  int get scannedCount => scannedRows.length;

  int get missingCount => missingRows.length;

  @override
  void onInit() {
    super.onInit();
    loadPickupList();
    final args = Get.arguments;
    if (args is SectorPickupRow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openPickupRow(args);
      });
    } else if (args is String && args.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final row = pickupRows.firstWhereOrNull(
          (r) => r.id?.trim() == args.trim(),
        );
        if (row != null) {
          openPickupRow(row);
        } else {
          pickupIdController.text = args.trim();
          prefillPickupDefaults();
        }
      });
    } else {
      prefillPickupDefaults();
    }
  }

  @override
  void onClose() {
    pickupIdController.dispose();
    mawbController.dispose();
    originHubController.dispose();
    destHubController.dispose();
    pickupDateController.dispose();
    pickupTimeController.dispose();
    pickedByController.dispose();
    flightInfoController.dispose();
    bagSealController.dispose();
    docketController.dispose();
    remarksController.dispose();
    docketFocusNode.dispose();
    bagSealFocusNode.dispose();
    super.onClose();
  }

  OutboundBranchListController? get _branchList {
    if (!Get.isRegistered<OutboundBranchListController>()) return null;
    return Get.find<OutboundBranchListController>();
  }

  String _hubLabel(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return '';
    final branch = _branchList?.displayLabelForId(t);
    if (branch != null && branch != '—' && branch.trim().isNotEmpty) {
      return branch.trim();
    }
    return t;
  }

  void _snack(String message, {bool isError = false}) {
    Get.snackbar(
      'Sector pickup',
      message,
      duration: Duration(seconds: isError ? 4 : 3),
    );
  }

  Future<String?> _branchIdOrSnack() async {
    final ctx = await OutboundAuthContext.load();
    final branchId = ctx.branchId?.trim();
    if (branchId == null || branchId.isEmpty) {
      _snack('Messenger branch is missing — log in again', isError: true);
      return null;
    }
    return branchId;
  }

  String _messageFromResponse(dynamic data, {String fallback = ''}) {
    final env = OutboundApiEnvelope.fromDynamic(data);
    final msg = env.message?.trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return fallback;
  }

  void _feedbackFromResponse(APIResponse<dynamic> response) {
    response.when(
      success: (data) {
        final msg = _messageFromResponse(data);
        if (msg.isNotEmpty) _snack(msg);
      },
      error: (e) => _snack(e.message, isError: true),
    );
  }

  Future<void> loadPickupList() async {
    isListLoading.value = true;
    try {
      final rows = await _repo.sectorPickupList();
      pickupRows.assignAll(rows);
    } finally {
      isListLoading.value = false;
    }
  }

  void openPickupList() {
    Get.offNamed(Routes.OUTBOUND_SECTOR_PICKUP_LIST);
  }

  void resetSession() {
    pickupIdController.clear();
    mawbController.clear();
    originHubController.clear();
    destHubController.clear();
    pickupDateController.clear();
    pickupTimeController.clear();
    pickedByController.clear();
    flightInfoController.clear();
    bagSealController.clear();
    docketController.clear();
    remarksController.clear();
    _pendingBagSeal = null;
    scannedRows.clear();
    missingRows.clear();
    prefillPickupDefaults();
  }

  /// Default pickup date/time to now; picked-by to logged-in messenger name.
  void prefillPickupDefaults() {
    final now = DateTime.now();
    if (pickupDateController.text.trim().isEmpty) {
      pickupDateController.text = OutboundApiParams.formatReportDate(now);
    }
    if (pickupTimeController.text.trim().isEmpty) {
      pickupTimeController.text = _formatPickupTime(
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      );
    }
    if (pickedByController.text.trim().isEmpty) {
      _prefillPickedByFromProfile();
    }
  }

  Future<void> _prefillPickedByFromProfile() async {
    if (pickedByController.text.trim().isNotEmpty) return;
    final user = await LocalStorage().getUserLocalData();
    final name = user?.messangerdetail?.name?.trim();
    if (name != null && name.isNotEmpty) {
      pickedByController.text = name;
    }
  }

  void openPickupRow(SectorPickupRow row) {
    applyPickupRow(row);
    final pickupId = row.id?.trim();
    if (pickupId != null && pickupId.isNotEmpty) {
      fetchPickupDetail(pickupId);
      return;
    }
    final mawb = row.mawbNo?.trim();
    if (mawb != null && mawb.isNotEmpty) {
      fetchLinehaulForMawb(mawb);
    }
  }

  void applyPickupRow(SectorPickupRow row) {
    pickupIdController.text = row.id?.trim() ?? '';
    mawbController.text = row.mawbNo?.trim() ?? '';
    pickupDateController.text = row.pickupDate?.trim() ?? '';
    pickupTimeController.text = _formatPickupTime(row.pickupTime);
    pickedByController.text = row.pickedBy?.trim() ?? '';
    originHubController.text = row.displayOriginHub;
    destHubController.text = row.displayDestHub;
    final flight = row.flightNo?.trim();
    if (flight != null && flight.isNotEmpty) {
      flightInfoController.text = flight;
    }
    prefillPickupDefaults();
  }

  String _formatPickupTime(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) return '';
    if (t.length >= 5 && t.contains(':')) return t.substring(0, 5);
    return t;
  }

  Future<void> onMawbSubmitted() async {
    await resolveMawb(mawbController.text.trim());
  }

  Future<void> onMawbScanned(String value) async {
    mawbController.text = value.trim();
    await resolveMawb(value.trim());
  }

  Future<void> resolveMawb(String mawb) async {
    final code = mawb.trim();
    if (code.isEmpty) {
      _snack('Enter or scan MAWB number', isError: true);
      return;
    }
    mawbController.text = code;

    final row = pickupRows.firstWhereOrNull(
      (r) => (r.mawbNo ?? '').trim().toLowerCase() == code.toLowerCase(),
    );
    if (row != null) {
      applyPickupRow(row);
    } else {
      _snack('MAWB not in pickup list — enter pickup details manually',
          isError: true);
    }

    await fetchLinehaulForMawb(code);
    docketFocusNode.requestFocus();
  }

  Future<void> fetchPickupDetail(String pickupId) async {
    final id = pickupId.trim();
    if (id.isEmpty) return;

    isBusy.value = true;
    try {
      final detail = await _repo.pickupDetail(id);
      if (detail == null) {
        final mawb = mawbController.text.trim();
        if (mawb.isNotEmpty) await fetchLinehaulForMawb(mawb);
        return;
      }
      _applyPickupDetail(detail);
      final expected = detail.shipmentList
          .map(
            (s) => SectorPickupExpectedShipment(
              docketNo: s.shipmentId ?? s.shipmentInvoiceNo ?? '',
              pkgs: '1',
            ),
          )
          .where((e) => e.docketNo.trim().isNotEmpty)
          .toList();
      _applyExpectedShipments(expected);
    } finally {
      isBusy.value = false;
    }
  }

  void _applyPickupDetail(PickupDetail detail) {
    pickupIdController.text = detail.id?.trim() ?? pickupIdController.text;
    if (detail.mawbNo?.trim().isNotEmpty == true) {
      mawbController.text = detail.mawbNo!.trim();
    }
    if (detail.pickupDate?.trim().isNotEmpty == true) {
      pickupDateController.text = detail.pickupDate!.trim();
    }
    if (detail.pickupTime?.trim().isNotEmpty == true) {
      pickupTimeController.text = _formatPickupTime(detail.pickupTime);
    }
    if (detail.pickedBy?.trim().isNotEmpty == true) {
      pickedByController.text = detail.pickedBy!.trim();
    }
    if (detail.originHub?.trim().isNotEmpty == true) {
      originHubController.text = detail.originHub!.trim();
    } else if (detail.originBranch?.trim().isNotEmpty == true) {
      originHubController.text = detail.originBranch!.trim();
    }
    if (detail.destinationHub?.trim().isNotEmpty == true) {
      destHubController.text = detail.destinationHub!.trim();
    } else if (detail.destinationBranch?.trim().isNotEmpty == true) {
      destHubController.text = detail.destinationBranch!.trim();
    }
    if (detail.flightNo?.trim().isNotEmpty == true) {
      flightInfoController.text = detail.flightNo!.trim();
    }
    prefillPickupDefaults();
  }

  Future<void> fetchLinehaulForMawb(String mawb) async {
    final ref = mawb.trim();
    if (ref.isEmpty) return;

    isBusy.value = true;
    try {
      final r = await _repo.fetchLinehaulDetails(ref);
      await r.when(
        success: (data) async {
          final detail = LinehaulDetail.fromDynamic(data);
          _applyLinehaulDetail(detail);

          final expected = <SectorPickupExpectedShipment>[
            ...SectorPickupExpectedShipment.listFromLinehaulRaw(data),
          ];

          for (final manifest in detail.manifests) {
            final code = manifest.manifestNo?.trim().isNotEmpty == true
                ? manifest.manifestNo!.trim()
                : manifest.id?.trim();
            if (code == null || code.isEmpty) continue;
            final mr = await _repo.fetchManifestDetailsByRefs([code]);
            mr.when(
              success: (manifestData) {
                final md = ManifestDetail.fromDynamic(manifestData);
                for (final shipment in md.shipments) {
                  expected.add(
                    SectorPickupExpectedShipment.fromManifestShipment(shipment),
                  );
                }
              },
              error: (_) {},
            );
          }

          _applyExpectedShipments(expected);
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  void _applyLinehaulDetail(LinehaulDetail detail) {
    final origin = detail.origin?.trim();
    final dest = detail.destination?.trim();
    if (origin != null && origin.isNotEmpty) {
      originHubController.text = _hubLabel(origin);
    }
    if (dest != null && dest.isNotEmpty) {
      destHubController.text = _hubLabel(dest);
    }

    final airline = detail.airline?.trim();
    final flight = detail.flightNo?.trim();
    final parts = <String>[
      if (airline != null && airline.isNotEmpty) airline,
      if (flight != null && flight.isNotEmpty) flight,
    ];
    if (parts.isNotEmpty) {
      flightInfoController.text = parts.join(' / ');
    }

    final mawb = detail.mawbNo ?? detail.airwayBillNo ?? detail.tripNo;
    if (mawb != null && mawb.trim().isNotEmpty) {
      mawbController.text = mawb.trim();
    }
  }

  void _applyExpectedShipments(List<SectorPickupExpectedShipment> expected) {
    final scannedKeys =
        scannedRows.map((e) => e.sessionKey).toSet();
    final unique = <String, SectorPickupExpectedShipment>{};
    for (final row in expected) {
      final key = row.sessionKey;
      if (key.isEmpty || scannedKeys.contains(key)) continue;
      unique[key] = row;
    }
    missingRows.assignAll(
      unique.values.map((e) => e.toMissingRow()).toList(),
    );
  }

  Future<void> onBagSealScanned(String value) async {
    final seal = value.trim();
    if (seal.isEmpty) return;
    bagSealController.text = seal;
    _pendingBagSeal = seal;
    docketFocusNode.requestFocus();
  }

  void onBagSealSubmitted() {
    final seal = bagSealController.text.trim();
    _pendingBagSeal = seal.isEmpty ? null : seal;
    docketFocusNode.requestFocus();
  }

  Future<void> onDocketSubmitted() async {
    await sectorPickupScan();
  }

  Future<void> onDocketScanned(String value) async {
    docketController.text = value.trim();
    await sectorPickupScan();
  }

  Future<void> sectorPickupScan() async {
    final pickupId = pickupIdController.text.trim();
    final docket = docketController.text.trim();
    if (pickupId.isEmpty) {
      _snack(
        'Pickup id is required — open an existing pickup from the list (new pickups are created server-side when linehaul arrives)',
        isError: true,
      );
      return;
    }
    if (docket.isEmpty) {
      _snack('Scan shipment docket', isError: true);
      return;
    }

    final branchId = await _branchIdOrSnack();
    if (branchId == null) return;

    isBusy.value = true;
    try {
      final r = await _repo.sectorPickupScan(
        pickupId: pickupId,
        docketNo: docket,
        status: 'Picked',
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );

      var ok = false;
      r.when(
        success: (_) => ok = true,
        error: (e) {
          if (outboundIsBenignDuplicate(e.message)) ok = true;
        },
      );

      if (ok) {
        _addScannedDocket(docket);
        _feedbackFromResponse(r);
      } else {
        _feedbackFromResponse(r);
      }
    } finally {
      isBusy.value = false;
    }
  }

  void _addScannedDocket(String docket) {
    final key = docket.trim().toLowerCase();
    final seal = _pendingBagSeal ?? bagSealController.text.trim();
    final missing = missingRows.firstWhereOrNull((r) => r.sessionKey == key);
    final pkgs = missing?.pkgs;

    scannedRows.removeWhere((r) => r.sessionKey == key);
    scannedRows.add(
      SectorPickupScannedRow(
        docketNo: docket.trim(),
        sealNo: seal.isEmpty ? missing?.sealNo : seal,
        pkgs: pkgs,
      ),
    );
    missingRows.removeWhere((r) => r.sessionKey == key);

    bagSealController.clear();
    docketController.clear();
    _pendingBagSeal = null;
    scrollToScannedTable.value++;
    docketFocusNode.requestFocus();
  }

  void removeScannedRow(SectorPickupScannedRow row) {
    scannedRows.removeWhere((r) => r.sessionKey == row.sessionKey);
    missingRows.add(
      SectorPickupMissingRow(
        docketNo: row.docketNo,
        sealNo: row.sealNo,
        pkgs: row.pkgs,
        status: SectorPickupMissingStatus.missing,
      ),
    );
  }

  Future<void> markNotPicked(SectorPickupMissingRow row) async {
    final branchId = await _branchIdOrSnack();
    if (branchId == null) return;

    isBusy.value = true;
    try {
      final r = await _repo.markNotPicked(
        pickupId: pickupIdController.text.trim(),
        docketNo: row.docketNo,
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      _feedbackFromResponse(r);
      r.when(
        success: (_) => _updateMissingStatus(
          row,
          SectorPickupMissingStatus.notPicked,
        ),
        error: (e) {
          if (outboundIsBenignDuplicate(e.message)) {
            _updateMissingStatus(row, SectorPickupMissingStatus.notPicked);
          }
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> addMissedShipment(SectorPickupMissingRow row) async {
    final branchId = await _branchIdOrSnack();
    if (branchId == null) return;

    isBusy.value = true;
    try {
      final r = await _repo.addMissedShipment(
        pickupId: pickupIdController.text.trim(),
        docketNo: row.docketNo,
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      _feedbackFromResponse(r);
      r.when(
        success: (_) => _updateMissingStatus(
          row,
          SectorPickupMissingStatus.missed,
        ),
        error: (e) {
          if (outboundIsBenignDuplicate(e.message)) {
            _updateMissingStatus(row, SectorPickupMissingStatus.missed);
          }
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  void _updateMissingStatus(SectorPickupMissingRow row, String status) {
    final idx = missingRows.indexWhere((r) => r.sessionKey == row.sessionKey);
    if (idx < 0) return;
    missingRows[idx] = row.copyWith(status: status);
  }
}
