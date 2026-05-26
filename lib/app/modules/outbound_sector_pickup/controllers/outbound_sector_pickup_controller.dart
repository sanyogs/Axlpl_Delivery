import 'package:axlpl_delivery/app/data/models/outbound/outbound_api_envelope.dart';
import 'package:axlpl_delivery/app/data/models/outbound/pickup_report_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_repository_retry.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundSectorPickupController extends GetxController {
  OutboundSectorPickupController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final pickupRows = <SectorPickupRow>[].obs;
  final pickupReportRows = <PickupReportRow>[].obs;

  final pickupIdController = TextEditingController();
  final docketController = TextEditingController();
  final scanStatus = RxnString();
  static const scanStatusOptions = ['Picked', 'Missed'];
  final remarksController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();

  @override
  void onClose() {
    pickupIdController.dispose();
    docketController.dispose();
    remarksController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    super.onClose();
  }

  void _snack(String message, {bool isError = false}) {
    Get.snackbar(
      'Sector pickup',
      message,
      duration: Duration(seconds: isError ? 4 : 3),
    );
  }

  String? _pickupIdError() =>
      OutboundValidation.validatePickupId(pickupIdController.text);

  String? _docketError() => OutboundValidation.validateDocket(docketController.text);

  String? _scanStatusError() {
    final st = scanStatus.value?.trim();
    if (st == null || st.isEmpty) return 'Select scan status';
    return null;
  }

  /// Pickup id + docket required for scan / mark not picked / add missed.
  bool _requirePickupAndDocket() {
    final pickupErr = _pickupIdError();
    if (pickupErr != null) {
      _snack(
        pickupRows.isEmpty
            ? '$pickupErr — load the list and tap a row, or type pickup id'
            : '$pickupErr — tap a pickup row or type pickup id',
        isError: true,
      );
      return false;
    }
    final docketErr = _docketError();
    if (docketErr != null) {
      _snack(docketErr, isError: true);
      return false;
    }
    return true;
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

  String _messageFromResponse(dynamic data, {String fallback = 'Done'}) {
    final env = OutboundApiEnvelope.fromDynamic(data);
    final msg = env.message?.trim();
    if (msg != null && msg.isNotEmpty) return msg;
    return fallback;
  }

  void _feedbackFromResponse(APIResponse<dynamic> response, {String okFallback = 'Done'}) {
    response.when(
      success: (data) {
        final msg = _messageFromResponse(data, fallback: okFallback);
        if (outboundIsBenignDuplicate(msg)) {
          _snack('Already recorded — $msg');
        } else {
          _snack(msg);
        }
      },
      error: (e) {
        _snack(e.message, isError: true);
      },
    );
  }

  Future<void> loadPickupList() async {
    isBusy.value = true;
    try {
      final rows = await _repo.sectorPickupList();
      pickupRows.assignAll(rows);
      if (rows.isEmpty) {
        final msg = _repo.lastMessage.trim().isNotEmpty
            ? _repo.lastMessage
            : 'No pickups found for your account';
        _snack(msg, isError: _repo.lastMessage.isNotEmpty);
      } else {
        _snack('Loaded ${rows.length} pickup(s)');
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> sectorPickupScan() async {
    if (!_requirePickupAndDocket()) return;
    final statusErr = _scanStatusError();
    if (statusErr != null) {
      _snack(statusErr, isError: true);
      return;
    }
    final branchId = await _branchIdOrSnack();
    if (branchId == null) return;

    isBusy.value = true;
    try {
      final r = await _repo.sectorPickupScan(
        pickupId: pickupIdController.text.trim(),
        docketNo: docketController.text.trim(),
        status: scanStatus.value!.trim(),
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      _feedbackFromResponse(r, okFallback: 'Pickup scan saved');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> markNotPicked() async {
    if (!_requirePickupAndDocket()) return;
    final branchId = await _branchIdOrSnack();
    if (branchId == null) return;

    isBusy.value = true;
    try {
      final r = await _repo.markNotPicked(
        pickupId: pickupIdController.text.trim(),
        docketNo: docketController.text.trim(),
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      _feedbackFromResponse(r, okFallback: 'Marked not picked');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> addMissedShipment() async {
    if (!_requirePickupAndDocket()) return;
    final branchId = await _branchIdOrSnack();
    if (branchId == null) return;

    isBusy.value = true;
    try {
      final r = await _repo.addMissedShipment(
        pickupId: pickupIdController.text.trim(),
        docketNo: docketController.text.trim(),
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      _feedbackFromResponse(r, okFallback: 'Missed shipment added');
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> pickupReport() async {
    isBusy.value = true;
    try {
      final r = await _repo.pickupReport(
        startDate: reportStartController.text.trim(),
        endDate: reportEndController.text.trim(),
      );
      r.when(
        success: (data) {
          pickupReportRows.assignAll(PickupReportRow.listFromDynamic(data));
          if (pickupReportRows.isEmpty) {
            _snack(_messageFromResponse(data, fallback: 'No report rows'));
          } else {
            _snack(
              'Report ready — ${pickupReportRows.length} status group(s)',
            );
          }
        },
        error: (e) => _snack(e.message, isError: true),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void applyPickupIdFromRow(SectorPickupRow row) {
    final id = row.id;
    if (id == null || id.isEmpty) {
      _snack('This row has no pickup id — choose another row', isError: true);
      return;
    }
    pickupIdController.text = id;
    final mawb = row.mawbNo?.trim();
    if (mawb != null && mawb.isNotEmpty) {
      _snack('Pickup $id · MAWB $mawb');
    } else {
      _snack('Pickup $id selected');
    }
  }
}
