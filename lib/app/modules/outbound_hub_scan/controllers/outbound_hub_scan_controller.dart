import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_response_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_log_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/shipment_scan_event_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
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
  final lastResponseText = ''.obs;
  final shipmentHintText = ''.obs;
  final hubScanLogs = <HubScanLog>[].obs;
  final shipmentHistory = <ShipmentScanEvent>[].obs;

  final docketController = TextEditingController();
  final scanHistoryDocketController = TextEditingController();
  final hubScanLimit = TextEditingController();

  final status = 'Hub In'.obs;
  final statuses = const ['Hub In', 'Hub Out'];

  @override
  void onInit() {
    super.onInit();
    ever(_branchList.isLoadingBranches, (loading) {
      if (loading == false && _branchList.selectedBranchIdOrNull != null) {
        loadHubScanLogs();
      }
    });
  }

  /// History field first, else main scan docket (copied into history field).
  String? _resolveHistoryDocket() {
    final fromHistory = scanHistoryDocketController.text.trim();
    if (fromHistory.isNotEmpty) return fromHistory;
    final fromScan = docketController.text.trim();
    if (fromScan.isEmpty) return null;
    scanHistoryDocketController.text = fromScan;
    return fromScan;
  }

  void useScanDocketForHistory() {
    final docket = docketController.text.trim();
    if (docket.isEmpty) {
      Get.snackbar('Hub scan', 'Enter docket on scan field first');
      return;
    }
    scanHistoryDocketController.text = docket;
    loadShipmentScanHistory();
  }

  @override
  void onClose() {
    docketController.dispose();
    scanHistoryDocketController.dispose();
    hubScanLimit.dispose();
    super.onClose();
  }

  Future<void> submitHubScan() async {
    final docket = docketController.text.trim();
    final branchId = _branchList.selectedBranchIdOrNull;
    if (docket.isEmpty || branchId == null) {
      Get.snackbar('Hub scan', 'Docket no and branch / hub are required');
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
      r.when(
        success: (data) {
          final scan = HubScanResponse.fromDynamic(data);
          lastResponseText.value = scan.isOk
              ? '${scan.successMessage ?? 'OK'} — ${scan.docketNo ?? scan.shipmentId ?? ''}'
              : OutboundDataParse.pretty(data);
          scanHistoryDocketController.text = docket;
          loadHubScanLogs();
          loadShipmentScanHistory();
        },
        error: (_) {},
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
    final branchId = _branchList.selectedBranchIdOrNull;
    if (branchId == null) {
      Get.snackbar('Hub scan', 'Select branch / hub first');
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
        lastResponseText.value = rows.isEmpty
            ? 'No hub scan rows for branch $branchId.'
            : '${rows.length} row(s) for branch $branchId.';
        Get.snackbar(
          'Outbound',
          rows.isEmpty ? 'No logs for branch $branchId' : 'Loaded ${rows.length} log(s)',
        );
      }
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> loadShipmentScanHistory() async {
    final docket = _resolveHistoryDocket();
    if (docket == null) {
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
        lastResponseText.value = rows.isEmpty
            ? 'No scan history for $docket.'
            : '${rows.length} event(s) for $docket.';
        Get.snackbar(
          'Outbound',
          rows.isEmpty ? 'No history for $docket' : 'Loaded ${rows.length} event(s)',
        );
      }
    } finally {
      isBusy.value = false;
    }
  }
}
