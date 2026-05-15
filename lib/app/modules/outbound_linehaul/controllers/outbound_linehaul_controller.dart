import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_test_ids.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundLinehaulController extends GetxController {
  OutboundLinehaulController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final lastResponseText = ''.obs;
  final linehaulRows = <OutboundLinehaulRow>[].obs;

  List<Map<String, dynamic>> get listRows =>
      linehaulRows.map((r) => r.asMap).toList();

  final manifestIdsController = TextEditingController();
  final vehicleController = TextEditingController();
  final driverController = TextEditingController();
  final listStatusController = TextEditingController(text: 'In Transit');
  final linehaulIdController = TextEditingController();
  final updateStatusController = TextEditingController(text: 'ARRIVED');
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    final d =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    reportStartController.text = d;
    reportEndController.text = d;
    if (OutboundTestIds.manifestId.isNotEmpty) {
      manifestIdsController.text = OutboundTestIds.manifestId;
    }
  }

  @override
  void onClose() {
    manifestIdsController.dispose();
    vehicleController.dispose();
    driverController.dispose();
    listStatusController.dispose();
    linehaulIdController.dispose();
    updateStatusController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    super.onClose();
  }

  Future<void> assignLinehaul() async {
    isBusy.value = true;
    try {
      final r = await _repo.assignLinehaul(
        manifestIdsCommaSeparated: manifestIdsController.text.trim(),
        vehicleNo: vehicleController.text.trim(),
        driverName: driverController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
      );
      r.when(
        success: (data) {
          final created = OutboundMutationResult.fromDynamic(data);
          final ref = created.effectiveLinehaulRef;
          if (ref != null && ref.isNotEmpty) {
            linehaulIdController.text = ref;
          }
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> listLinehauls() async {
    final status = listStatusController.text.trim();
    if (status.isEmpty) {
      Get.snackbar('Linehaul', 'Status filter required');
      return;
    }
    isBusy.value = true;
    try {
      final rows = await _repo.listLinehauls(status: status);
      linehaulRows.assignAll(rows);
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        lastResponseText.value = _repo.lastMessage;
        Get.snackbar('Linehaul', _repo.lastMessage);
      } else {
        lastResponseText.value = rows.isEmpty
            ? 'No linehaul rows returned.'
            : OutboundDataParse.pretty(rows.map((r) => r.asMap).toList());
        Get.snackbar(
          'Linehaul',
          rows.isEmpty ? 'Success (no rows)' : '${rows.length} row(s)',
        );
      }
    } finally {
      isBusy.value = false;
    }
  }

  void applyLinehaulIdFromListRow(Map<String, dynamic> row) {
    final id = OutboundLinehaulRow(row).linehaulId;
    if (id != null) linehaulIdController.text = id;
  }

  Future<void> getLinehaulDetails() async {
    isBusy.value = true;
    try {
      final r = await _repo.fetchLinehaulDetails(
        linehaulIdController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> updateLinehaulStatus() async {
    final ctx = await OutboundAuthContext.load();
    final branchId = ctx.branchId;
    if (branchId == null || branchId.isEmpty) {
      Get.snackbar('Linehaul', 'Branch id missing');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.updateLinehaulStatus(
        linehaulId: linehaulIdController.text.trim(),
        status: updateStatusController.text.trim(),
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> linehaulReport() async {
    isBusy.value = true;
    try {
      final r = await _repo.linehaulReport(
        startDate: reportStartController.text.trim(),
        endDate: reportEndController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Linehaul',
      );
    } finally {
      isBusy.value = false;
    }
  }

  void openLinehaulDetailPage() {
    final id = linehaulIdController.text.trim();
    if (id.isEmpty) {
      Get.snackbar('Linehaul', 'Enter linehaul id');
      return;
    }
    Get.toNamed(
      Routes.OUTBOUND_REMOTE_DETAIL,
      arguments: {'kind': 'linehaul', 'id': id},
    );
  }
}
