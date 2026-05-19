import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
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
  final linehaulDetail = Rxn<LinehaulDetail>();

  final listFilterStatus = 'In Transit'.obs;
  final updateStatus = 'ARRIVED'.obs;

  static const listStatusOptions = [
    'In Transit',
    'Dispatched',
    'ARRIVED',
    'Completed',
  ];

  static const updateStatusOptions = [
    'ARRIVED',
    'In Transit',
    'Dispatched',
    'Completed',
  ];

  List<Map<String, dynamic>> get listRows =>
      linehaulRows.map((r) => r.asMap).toList();

  final manifestCodesController = TextEditingController();
  final vehicleController = TextEditingController();
  final driverController = TextEditingController();
  final tripNoController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();

  @override
  void onClose() {
    manifestCodesController.dispose();
    vehicleController.dispose();
    driverController.dispose();
    tripNoController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    super.onClose();
  }

  Future<void> assignLinehaul() async {
    final manifests = manifestCodesController.text.trim();
    final vehicle = vehicleController.text.trim();
    final driver = driverController.text.trim();
    if (manifests.isEmpty) {
      Get.snackbar('Linehaul', 'Manifest code(s) required');
      return;
    }
    if (vehicle.isEmpty || driver.isEmpty) {
      Get.snackbar('Linehaul', 'Vehicle no and driver name are required');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.assignLinehaul(
        manifestIdsCommaSeparated: manifests,
        vehicleNo: vehicle,
        driverName: driver,
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
            tripNoController.text = ref;
          }
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> listLinehauls() async {
    final status = listFilterStatus.value;
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
    applyLinehaulFromRow(OutboundLinehaulRow.fromJson(row));
  }

  void applyLinehaulFromRow(OutboundLinehaulRow row) {
    final ref = row.effectiveRef;
    if (ref != null) tripNoController.text = ref;
  }

  Future<void> getLinehaulDetails() async {
    isBusy.value = true;
    try {
      final r = await _repo.fetchLinehaulDetails(tripNoController.text.trim());
      r.when(
        success: (data) {
          final detail = LinehaulDetail.fromDynamic(data);
          linehaulDetail.value = detail;
          final summary = detail.summaryLines;
          lastResponseText.value = summary.isNotEmpty
              ? summary.join('\n')
              : OutboundDataParse.pretty(data);
          Get.snackbar('Linehaul', 'Linehaul details loaded');
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Linehaul', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> updateLinehaulStatus() async {
    final trip = tripNoController.text.trim();
    if (trip.isEmpty) {
      Get.snackbar('Linehaul', 'Trip no / linehaul ref is required');
      return;
    }
    isBusy.value = true;
    try {
      final ctx = await OutboundAuthContext.load();
      final branchId = OutboundAuthContext.branchIdForScan(ctx.branchId);
      final r = await _repo.updateLinehaulStatus(
        linehaulId: trip,
        status: updateStatus.value,
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
    final ref = tripNoController.text.trim();
    if (ref.isEmpty) {
      Get.snackbar('Linehaul', 'Enter trip no from assign or list');
      return;
    }
    Get.toNamed(
      Routes.OUTBOUND_REMOTE_DETAIL,
      arguments: {'kind': 'linehaul', 'id': ref},
    );
  }
}
