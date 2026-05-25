import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_manifest_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundManifestController extends GetxController {
  OutboundManifestController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final lastResponseText = ''.obs;
  final manifestRows = <OutboundManifestRow>[].obs;
  final manifestDetail = Rxn<ManifestDetail>();
  final manifestReportData = Rxn<ManifestReport>();
  final printManifestDetail = Rxn<ManifestDetail>();

  final selectedOriginDepotId = RxnString();
  final selectedDestDepotId = RxnString();
  final selectedListDepotId = RxnString();

  List<Map<String, dynamic>> get listRows =>
      manifestRows.map((r) => r.asMap).toList();

  final bagCodesController = TextEditingController();
  final manifestCodeController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();

  @override
  void onClose() {
    bagCodesController.dispose();
    manifestCodeController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    super.onClose();
  }

  Future<void> createManifest() async {
    final origin = selectedOriginDepotId.value?.trim();
    final dest = selectedDestDepotId.value?.trim();
    if (origin == null || origin.isEmpty || dest == null || dest.isEmpty) {
      Get.snackbar('Manifest', 'Select origin and destination depot');
      return;
    }
    if (bagCodesController.text.trim().isEmpty) {
      Get.snackbar('Manifest', 'At least one bag code is required');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.createManifest(
        bagIdsCommaSeparated: bagCodesController.text.trim(),
        originBranchId: origin,
        destinationBranchId: dest,
      );
      r.when(
        success: (data) {
          lastResponseText.value = '';
          final result = OutboundMutationResult.fromDynamic(data);
          final code = result.effectiveManifestRef;
          if (code != null && code.isNotEmpty) {
            manifestCodeController.text = code;
          }
          Get.snackbar('Manifest', 'Manifest created');
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Manifest', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> listManifests() async {
    final branch = selectedListDepotId.value?.trim();
    if (branch == null || branch.isEmpty) {
      Get.snackbar('Manifest', 'Select depot for list');
      return;
    }
    isBusy.value = true;
    try {
      final rows = await _repo.listManifests(branchId: branch);
      manifestRows.assignAll(rows);
      lastResponseText.value = '';
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        lastResponseText.value = _repo.lastMessage;
        Get.snackbar('Manifest', _repo.lastMessage);
      } else {
        Get.snackbar(
          'Manifest',
          rows.isEmpty ? 'No manifests found' : '${rows.length} manifest(s)',
        );
      }
    } finally {
      isBusy.value = false;
    }
  }

  void applyManifestIdFromListRow(Map<String, dynamic> row) {
    applyManifestFromRow(OutboundManifestRow.fromJson(row));
  }

  void applyManifestFromRow(OutboundManifestRow row) {
    final code = row.manifestNo ?? row.manifestId;
    if (code == null || code.isEmpty) return;
    manifestCodeController.text = code;
    getManifestDetails();
  }

  Future<void> getManifestDetails() async {
    final code = manifestCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Manifest', 'Enter manifest code');
      return;
    }
    isBusy.value = true;
    manifestDetail.value = null;
    try {
      final r = await _repo.fetchManifestDetails(code);
      r.when(
        success: (data) {
          final detail = ManifestDetail.fromDynamic(data);
          manifestDetail.value = detail;
          lastResponseText.value = '';
          Get.snackbar('Manifest', 'Details loaded');
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Manifest', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> manifestReport() async {
    isBusy.value = true;
    try {
      final r = await _repo.manifestReport(
        startDate: reportStartController.text.trim(),
        endDate: reportEndController.text.trim(),
        manifestNo: manifestCodeController.text.trim(),
      );
      r.when(
        success: (data) {
          final report = ManifestReport.fromDynamic(data);
          manifestReportData.value = report;
          lastResponseText.value = '';
          Get.snackbar('Manifest', 'Report ready');
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Manifest', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> printManifestData() async {
    final code = manifestCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Manifest', 'Enter manifest code');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.printManifestData(code);
      r.when(
        success: (data) {
          final detail = ManifestDetail.fromDynamic(data);
          printManifestDetail.value = detail;
          manifestDetail.value = detail;
          lastResponseText.value = '';
          Get.snackbar('Manifest', 'Print view ready');
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Manifest', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  void openManifestDetailPage() {
    final code = manifestCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Manifest', 'Enter or scan manifest code');
      return;
    }
    Get.toNamed(
      Routes.OUTBOUND_REMOTE_DETAIL,
      arguments: {'kind': 'manifest', 'id': code},
    );
  }
}
