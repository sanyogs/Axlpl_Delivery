import 'package:axlpl_delivery/app/data/models/outbound/outbound_api_envelope.dart';
import 'package:axlpl_delivery/app/data/models/outbound/pickup_report_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_repository_retry.dart';
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
        if (msg.isEmpty) return;
        if (outboundIsBenignDuplicate(msg)) {
          _snack(msg);
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
        final msg = _repo.lastMessage.trim();
        if (msg.isNotEmpty) _snack(msg, isError: true);
      } else {
        final msg = _repo.lastMessage.trim();
        if (msg.isNotEmpty) {
          _snack(msg);
        } else {
          _snack('${rows.length} pickup(s)');
        }
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> sectorPickupScan() async {
    final branchId = await _branchIdOrSnack();
    if (branchId == null) return;

    isBusy.value = true;
    try {
      final r = await _repo.sectorPickupScan(
        pickupId: pickupIdController.text.trim(),
        docketNo: docketController.text.trim(),
        status: scanStatus.value?.trim() ?? '',
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      _feedbackFromResponse(r);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> markNotPicked() async {
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
      _feedbackFromResponse(r);
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> addMissedShipment() async {
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
      _feedbackFromResponse(r);
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
          final msg = _messageFromResponse(data);
          if (msg.isNotEmpty) {
            _snack(msg);
          }
        },
        error: (e) => _snack(e.message, isError: true),
      );
    } finally {
      isBusy.value = false;
    }
  }

  void applyPickupIdFromRow(SectorPickupRow row) {
    pickupIdController.text = row.id?.trim() ?? '';
  }
}
