import 'package:axlpl_delivery/app/data/models/outbound/pickup_report_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_row_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundSectorPickupController extends GetxController {
  OutboundSectorPickupController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final lastResponseText = ''.obs;
  final pickupRows = <SectorPickupRow>[].obs;
  final pickupReportRows = <PickupReportRow>[].obs;

  final pickupIdController = TextEditingController();
  final docketController = TextEditingController();
  final scanStatus = 'Picked'.obs;
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

  Future<void> loadPickupList() async {
    isBusy.value = true;
    try {
      final rows = await _repo.sectorPickupList();
      pickupRows.assignAll(rows);
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        lastResponseText.value = _repo.lastMessage;
        Get.snackbar('Sector pickup', _repo.lastMessage);
      } else {
        lastResponseText.value =
            rows.isEmpty ? 'No pickups in list.' : '${rows.length} pickup(s).';
        Get.snackbar('Sector pickup', 'Loaded ${rows.length} row(s)');
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> sectorPickupScan() async {
    final pickupId = pickupIdController.text.trim();
    final docket = docketController.text.trim();
    if (pickupId.isEmpty || docket.isEmpty) {
      Get.snackbar('Sector pickup', 'Pickup id and docket no are required');
      return;
    }
    final ctx = await OutboundAuthContext.load();
    final branchId = ctx.branchId;
    if (branchId == null || branchId.isEmpty) {
      Get.snackbar('Sector pickup', 'Branch id missing');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.sectorPickupScan(
        pickupId: pickupIdController.text.trim(),
        docketNo: docketController.text.trim(),
        status: scanStatus.value,
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Sector pickup',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> markNotPicked() async {
    final ctx = await OutboundAuthContext.load();
    final branchId = ctx.branchId;
    if (branchId == null || branchId.isEmpty) {
      Get.snackbar('Sector pickup', 'Branch id missing');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.markNotPicked(
        pickupId: pickupIdController.text.trim(),
        docketNo: docketController.text.trim(),
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Sector pickup',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> addMissedShipment() async {
    final ctx = await OutboundAuthContext.load();
    final branchId = ctx.branchId;
    if (branchId == null || branchId.isEmpty) {
      Get.snackbar('Sector pickup', 'Branch id missing');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.addMissedShipment(
        pickupId: pickupIdController.text.trim(),
        docketNo: docketController.text.trim(),
        remarks: remarksController.text.trim(),
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Sector pickup',
      );
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
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Sector pickup',
      );
      r.when(
        success: (data) {
          pickupReportRows.assignAll(PickupReportRow.listFromDynamic(data));
          if (pickupReportRows.isNotEmpty) {
            lastResponseText.value = pickupReportRows
                .map((e) => '${e.status ?? ''}: ${e.count ?? '0'}')
                .join('\n');
          }
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  void applyPickupIdFromRow(SectorPickupRow row) {
    final id = row.id;
    if (id != null && id.isNotEmpty) {
      pickupIdController.text = id;
    }
    final mawb = row.mawbNo;
    if (mawb != null && mawb.isNotEmpty) {
      lastResponseText.value = 'Pickup $id · MAWB $mawb';
    }
  }
}
