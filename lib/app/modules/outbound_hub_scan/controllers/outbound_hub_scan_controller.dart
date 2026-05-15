import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_log_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/shipment_scan_event_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_test_ids.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundHubScanController extends GetxController {
  OutboundHubScanController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final lastResponseText = ''.obs;
  final shipmentHintText = ''.obs;
  final hubScanLogs = <HubScanLog>[].obs;
  final shipmentHistory = <ShipmentScanEvent>[].obs;

  final docketController = TextEditingController();
  final branchController = TextEditingController();
  final scanHistoryDocketController = TextEditingController();
  final hubScanLimit = TextEditingController(text: '50');

  final status = 'Hub In'.obs;
  final statuses = const ['Hub In', 'Hub Out'];

  @override
  void onInit() {
    super.onInit();
    _prefillBranch();
  }

  Future<void> _prefillBranch() async {
    final ctx = await OutboundAuthContext.load();
    branchController.text = OutboundAuthContext.branchIdForScan(ctx.branchId);
    if (OutboundTestIds.docket.isNotEmpty) {
      docketController.text = OutboundTestIds.docket;
      scanHistoryDocketController.text = OutboundTestIds.docket;
    }
  }

  @override
  void onClose() {
    docketController.dispose();
    branchController.dispose();
    scanHistoryDocketController.dispose();
    hubScanLimit.dispose();
    super.onClose();
  }

  Future<void> submitHubScan() async {
    final docket = docketController.text.trim();
    final branchId = branchController.text.trim();
    if (docket.isEmpty || branchId.isEmpty) {
      Get.snackbar('Outbound', 'Docket no and branch id are required');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.hubScanSubmit(
        docketNo: docket,
        branchId: branchId,
        status: status.value,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Hub scan',
      );
    } finally {
      isBusy.value = false;
    }
  }

  /// Optional shipment master hint (existing `getShipmentByConsignmentId`).
  Future<void> loadShipmentHint() async {
    final docket = docketController.text.trim();
    if (docket.isEmpty) {
      Get.snackbar('Hub scan', 'Enter docket no first');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.shipmentByDocket(docket);
      r.when(
        success: (data) {
          shipmentHintText.value = OutboundDataParse.pretty(data);
          Get.snackbar('Hub scan', 'Shipment hint loaded');
        },
        error: (e) {
          shipmentHintText.value = e.message;
          Get.snackbar('Hub scan', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> loadHubScanLogs() async {
    final branchId = branchController.text.trim();
    if (branchId.isEmpty) {
      Get.snackbar('Outbound', 'Branch id required');
      return;
    }
    final limit = int.tryParse(hubScanLimit.text.trim()) ?? 50;
    isBusy.value = true;
    try {
      final rows = await _repo.hubScanLogs(branchId: branchId, limit: limit);
      hubScanLogs.assignAll(rows);
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        Get.snackbar('Outbound', _repo.lastMessage);
        lastResponseText.value = _repo.lastMessage;
      } else {
        lastResponseText.value =
            rows.isEmpty ? 'No hub scan rows returned.' : '${rows.length} row(s).';
        Get.snackbar('Outbound', 'Loaded ${rows.length} log(s)');
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> loadShipmentScanHistory() async {
    final docket = scanHistoryDocketController.text.trim();
    if (docket.isEmpty) {
      Get.snackbar('Outbound', 'Docket no required for scan history');
      return;
    }
    isBusy.value = true;
    try {
      final rows = await _repo.shipmentScanHistory(docket);
      shipmentHistory.assignAll(rows);
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        Get.snackbar('Outbound', _repo.lastMessage);
        lastResponseText.value = _repo.lastMessage;
      } else {
        lastResponseText.value =
            rows.isEmpty ? 'No scan history.' : '${rows.length} event(s).';
        Get.snackbar('Outbound', 'Loaded ${rows.length} event(s)');
      }
    } finally {
      isBusy.value = false;
    }
  }
}
