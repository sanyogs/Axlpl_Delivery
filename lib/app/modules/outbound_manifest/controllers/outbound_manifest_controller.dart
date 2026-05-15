import 'package:axlpl_delivery/app/data/models/outbound/outbound_manifest_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_test_ids.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
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

  List<Map<String, dynamic>> get listRows =>
      manifestRows.map((r) => r.asMap).toList();

  final bagIdsController = TextEditingController();
  final originBranchController = TextEditingController();
  final destBranchController = TextEditingController();
  final manifestIdController = TextEditingController();
  final listBranchController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _prefill();
  }

  Future<void> _prefill() async {
    final ctx = await OutboundAuthContext.load();
    final listBranch = OutboundAuthContext.branchIdForLists(ctx.branchId);
    listBranchController.text = listBranch;
    originBranchController.text = listBranch;
    final now = DateTime.now();
    final d =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    reportStartController.text = d;
    reportEndController.text = d;
    if (OutboundTestIds.bagCode.isNotEmpty) {
      bagIdsController.text = OutboundTestIds.bagCode;
    }
    if (OutboundTestIds.manifestId.isNotEmpty) {
      manifestIdController.text = OutboundTestIds.manifestId;
    }
  }

  @override
  void onClose() {
    bagIdsController.dispose();
    originBranchController.dispose();
    destBranchController.dispose();
    manifestIdController.dispose();
    listBranchController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    super.onClose();
  }

  Future<void> createManifest() async {
    isBusy.value = true;
    try {
      final r = await _repo.createManifest(
        bagIdsCommaSeparated: bagIdsController.text.trim(),
        originBranchId: originBranchController.text.trim(),
        destinationBranchId: destBranchController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Manifest',
      );
      r.when(
        success: (data) {
          final id = OutboundMutationResult.fromDynamic(data).manifestId;
          if (id != null && id.isNotEmpty) {
            manifestIdController.text = id;
          }
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> listManifests() async {
    final ctx = await OutboundAuthContext.load();
    final branch = listBranchController.text.trim().isNotEmpty
        ? listBranchController.text.trim()
        : (ctx.branchId ?? '');
    if (branch.isEmpty) {
      Get.snackbar('Manifest', 'Branch id required');
      return;
    }
    isBusy.value = true;
    try {
      final rows = await _repo.listManifests(branchId: branch);
      manifestRows.assignAll(rows);
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        lastResponseText.value = _repo.lastMessage;
        Get.snackbar('Manifest', _repo.lastMessage);
      } else {
        lastResponseText.value = rows.isEmpty
            ? 'No manifest rows returned.'
            : OutboundDataParse.pretty(rows.map((r) => r.asMap).toList());
        Get.snackbar(
          'Manifest',
          rows.isEmpty ? 'Success (no rows)' : '${rows.length} row(s)',
        );
      }
    } finally {
      isBusy.value = false;
    }
  }

  void applyManifestIdFromListRow(Map<String, dynamic> row) {
    final rowModel = OutboundManifestRow(row);
    final id = rowModel.manifestId ?? rowModel.manifestNo;
    if (id != null) manifestIdController.text = id;
  }

  Future<void> getManifestDetails() async {
    isBusy.value = true;
    try {
      final r = await _repo.fetchManifestDetails(
        manifestIdController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Manifest',
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
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Manifest',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> printManifestData() async {
    isBusy.value = true;
    try {
      final r = await _repo.printManifestData(manifestIdController.text.trim());
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Manifest',
      );
    } finally {
      isBusy.value = false;
    }
  }

  void openManifestDetailPage() {
    final id = manifestIdController.text.trim();
    if (id.isEmpty) {
      Get.snackbar('Manifest', 'Enter manifest id');
      return;
    }
    Get.toNamed(
      Routes.OUTBOUND_REMOTE_DETAIL,
      arguments: {'kind': 'manifest', 'id': id},
    );
  }
}
