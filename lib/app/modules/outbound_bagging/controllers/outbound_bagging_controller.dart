import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_auth_context.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_test_ids.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundBaggingController extends GetxController {
  OutboundBaggingController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final isBusy = false.obs;
  final lastResponseText = ''.obs;
  final bagRows = <OutboundBagRow>[].obs;

  List<Map<String, dynamic>> get listRows =>
      bagRows.map((r) => r.asMap).toList();

  final originBranchController = TextEditingController();
  final destBranchController = TextEditingController();
  final bagCodeController = TextEditingController();
  final bagIdController = TextEditingController();
  final docketController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();
  final newBagIdController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _prefill();
  }

  Future<void> _prefill() async {
    final ctx = await OutboundAuthContext.load();
    final listBranch = OutboundAuthContext.branchIdForLists(ctx.branchId);
    originBranchController.text = listBranch;
    destBranchController.text = listBranch;
    final now = DateTime.now();
    final d =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    reportStartController.text = d;
    reportEndController.text = d;
    _prefillTestIds();
  }

  void _prefillTestIds() {
    if (!OutboundTestIds.hasAny) return;
    if (OutboundTestIds.docket.isNotEmpty) {
      docketController.text = OutboundTestIds.docket;
    }
    if (OutboundTestIds.bagCode.isNotEmpty) {
      bagCodeController.text = OutboundTestIds.bagCode;
      bagIdController.text = OutboundTestIds.bagCode;
    }
  }

  @override
  void onClose() {
    originBranchController.dispose();
    destBranchController.dispose();
    bagCodeController.dispose();
    bagIdController.dispose();
    docketController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    newBagIdController.dispose();
    super.onClose();
  }

  Future<void> createBag() async {
    isBusy.value = true;
    try {
      final r = await _repo.createBag(
        originBranchId: originBranchController.text.trim(),
        destinationBranchId: destBranchController.text.trim(),
        bagCode: bagCodeController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
      r.when(
        success: (data) {
          final created = OutboundMutationResult.fromDynamic(data);
          final ref = created.effectiveBagRef;
          if (ref != null && ref.isNotEmpty) {
            bagIdController.text = ref;
            if (created.bagCode != null) {
              bagCodeController.text = created.bagCode!;
            }
          }
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> addShipment() async {
    final ctx = await OutboundAuthContext.load();
    final branchId = OutboundAuthContext.branchIdForScan(ctx.branchId);
    isBusy.value = true;
    try {
      final r = await _repo.addShipmentToBag(
        bagId: bagIdController.text.trim(),
        docketNo: docketController.text.trim(),
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> getBagDetails() async {
    isBusy.value = true;
    try {
      final r = await _repo.fetchBagDetails(bagIdController.text.trim());
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> listBags() async {
    final ctx = await OutboundAuthContext.load();
    final branchId = originBranchController.text.trim().isNotEmpty
        ? originBranchController.text.trim()
        : (ctx.branchId ?? '');
    if (branchId.isEmpty) {
      Get.snackbar('Bagging', 'Branch id required');
      return;
    }
    isBusy.value = true;
    try {
      final rows = await _repo.listBags(branchId: branchId);
      bagRows.assignAll(rows);
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        lastResponseText.value = _repo.lastMessage;
        Get.snackbar('Bagging', _repo.lastMessage);
      } else {
        lastResponseText.value = rows.isEmpty
            ? 'No bag rows returned.'
            : OutboundDataParse.pretty(rows.map((r) => r.asMap).toList());
        Get.snackbar(
          'Bagging',
          rows.isEmpty ? 'Success (no rows)' : '${rows.length} row(s)',
        );
      }
    } finally {
      isBusy.value = false;
    }
  }

  void applyBagIdFromListRow(Map<String, dynamic> row) {
    final parsed = OutboundBagRow(row);
    final code = parsed.bagCode;
    final id = parsed.bagId;
    if (code != null && code.isNotEmpty) {
      bagCodeController.text = code;
      bagIdController.text = code;
    } else if (id != null && id.isNotEmpty) {
      bagIdController.text = id;
    }
  }

  Future<void> removeShipment() async {
    final ctx = await OutboundAuthContext.load();
    final branchId = ctx.branchId;
    if (branchId == null || branchId.isEmpty) {
      Get.snackbar('Bagging', 'Branch id missing');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.removeShipmentFromBag(
        bagId: bagIdController.text.trim(),
        docketNo: docketController.text.trim(),
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> lockBag() async {
    isBusy.value = true;
    try {
      final r = await _repo.lockBag(bagIdController.text.trim());
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> rebag() async {
    isBusy.value = true;
    try {
      final r = await _repo.rebagShipment(
        newBagId: newBagIdController.text.trim(),
        docketNo: docketController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> baggingReport() async {
    isBusy.value = true;
    try {
      final r = await _repo.baggingReport(
        startDate: reportStartController.text.trim(),
        endDate: reportEndController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
    } finally {
      isBusy.value = false;
    }
  }

  void openBagDetailPage() {
    final id = bagIdController.text.trim();
    if (id.isEmpty) {
      Get.snackbar('Bagging', 'Enter bag id');
      return;
    }
    Get.toNamed(
      Routes.OUTBOUND_REMOTE_DETAIL,
      arguments: {'kind': 'bag', 'id': id},
    );
  }
}
