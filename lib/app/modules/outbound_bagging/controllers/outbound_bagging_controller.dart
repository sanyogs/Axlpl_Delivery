import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/lock_bag_response_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_repository_retry.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundBaggingController extends GetxController {
  OutboundBaggingController({
    OutboundRepository? repo,
    OutboundBranchListController? branchList,
  })  : _repo = repo ?? Get.find<OutboundRepository>(),
        _branchList = branchList ?? Get.find<OutboundBranchListController>();

  final OutboundRepository _repo;
  final OutboundBranchListController _branchList;

  final isBusy = false.obs;
  final lastResponseText = ''.obs;
  final bagRows = <OutboundBagRow>[].obs;
  final bagDetail = Rxn<BagDetail>();
  final baggingReportData = Rxn<BaggingReport>();

  final selectedOriginDepotId = RxnString();
  final selectedDestDepotId = RxnString();

  List<Map<String, dynamic>> get listRows =>
      bagRows.map((r) => r.asMap).toList();

  final bagCodeController = TextEditingController();
  final createBagShipmentsController = TextEditingController();
  final bagCodeWorkingController = TextEditingController();
  final docketController = TextEditingController();
  final removeDocketController = TextEditingController();
  final reportStartController = TextEditingController();
  final reportEndController = TextEditingController();
  final newBagCodeController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    ever(_branchList.isLoadingBranches, (loading) {
      if (loading == false && _originId != null) {
        listBags();
      }
    });
  }

  @override
  void onClose() {
    bagCodeController.dispose();
    createBagShipmentsController.dispose();
    bagCodeWorkingController.dispose();
    docketController.dispose();
    removeDocketController.dispose();
    reportStartController.dispose();
    reportEndController.dispose();
    newBagCodeController.dispose();
    super.onClose();
  }

  String? get _originId => selectedOriginDepotId.value?.trim();
  String? get _destId => selectedDestDepotId.value?.trim();

  void useDocketForCreateBag() {
    final docket = docketController.text.trim();
    if (docket.isEmpty) {
      Get.snackbar('Bagging', 'Enter a shipment / docket in Scan shipments first');
      return;
    }
    createBagShipmentsController.text = docket;
  }

  Future<void> createBag() async {
    final origin = _originId;
    final dest = _destId;
    if (origin == null || origin.isEmpty || dest == null || dest.isEmpty) {
      Get.snackbar('Bagging', 'Select origin and destination depot');
      return;
    }
    final shipmentIds = OutboundApiParams.parseShipmentIdsCsv(
      createBagShipmentsController.text,
    );
    if (shipmentIds.isEmpty) {
      Get.snackbar(
        'Bagging',
        'At least one shipment id is required for bagging',
      );
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.createBag(
        originBranchId: origin,
        destinationBranchId: dest,
        bagCode: bagCodeController.text.trim(),
        shipmentIdsCsv: OutboundApiParams.shipmentIdsCsv(shipmentIds),
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
            bagCodeWorkingController.text = ref;
            if (created.bagCode != null) {
              bagCodeController.text = created.bagCode!;
            }
          }
          if (docketController.text.trim().isEmpty && shipmentIds.isNotEmpty) {
            docketController.text = shipmentIds.first;
          }
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> addShipment() async {
    final branchId = _originId;
    if (branchId == null || branchId.isEmpty) {
      Get.snackbar('Bagging', 'Select origin depot first');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.addShipmentToBag(
        bagId: bagCodeWorkingController.text.trim(),
        docketNo: docketController.text.trim(),
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
      r.when(
        success: (_) {
          getBagDetails();
          listBags();
        },
        error: (e) {
          if (outboundIsBenignDuplicate(e.message)) {
            getBagDetails();
          }
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> getBagDetails() async {
    final code = bagCodeWorkingController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Bagging', 'Enter bag code first');
      return;
    }
    isBusy.value = true;
    try {
      final r = await _repo.fetchBagDetails(code);
      r.when(
        success: (data) {
          final detail = BagDetail.fromDynamic(data);
          bagDetail.value = detail;
          final summary = detail.summaryLines;
          lastResponseText.value = summary.isNotEmpty
              ? summary.join('\n')
              : OutboundDataParse.pretty(data);
          Get.snackbar('Bagging', 'Bag details loaded');
        },
        error: (e) {
          lastResponseText.value = e.message;
          Get.snackbar('Bagging', e.message);
        },
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> listBags() async {
    final branchId = _originId;
    if (branchId == null || branchId.isEmpty) {
      return;
    }
    isBusy.value = true;
    try {
      final rows = await _repo.listBags(branchId: branchId);
      bagRows.assignAll(rows);
      if (rows.isEmpty && _repo.lastMessage.isNotEmpty) {
        lastResponseText.value = _repo.lastMessage;
      } else if (rows.isNotEmpty) {
        lastResponseText.value =
            '${rows.length} bag(s) at origin depot $branchId.';
      }
    } finally {
      isBusy.value = false;
    }
  }

  void applyBagIdFromListRow(Map<String, dynamic> row) {
    final parsed = OutboundBagRow.fromJson(row);
    final code = parsed.bagCode;
    final id = parsed.bagId;
    if (code != null && code.isNotEmpty) {
      bagCodeController.text = code;
      bagCodeWorkingController.text = code;
    } else if (id != null && id.isNotEmpty) {
      bagCodeWorkingController.text = id;
    }
  }

  Future<void> removeShipment() async {
    final branchId = _originId;
    if (branchId == null || branchId.isEmpty) {
      Get.snackbar('Bagging', 'Select origin depot first');
      return;
    }
    final docket = removeDocketController.text.trim().isNotEmpty
        ? removeDocketController.text.trim()
        : docketController.text.trim();
    isBusy.value = true;
    try {
      final r = await _repo.removeShipmentFromBag(
        bagId: bagCodeWorkingController.text.trim(),
        docketNo: docket,
        branchId: branchId,
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
      r.when(
        success: (_) => getBagDetails(),
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> lockBag() async {
    isBusy.value = true;
    try {
      final r = await _repo.lockBag(bagCodeWorkingController.text.trim());
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
      r.when(
        success: (data) {
          final locked = LockBagResponse.fromDynamic(data);
          lastResponseText.value = locked.isLocked
              ? 'Bag ${locked.bagCode ?? locked.bagId ?? ''} — ${locked.status}'
              : OutboundDataParse.pretty(data);
          getBagDetails();
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  Future<void> rebag() async {
    final docket = removeDocketController.text.trim().isNotEmpty
        ? removeDocketController.text.trim()
        : docketController.text.trim();
    isBusy.value = true;
    try {
      final r = await _repo.rebagShipment(
        newBagId: newBagCodeController.text.trim(),
        docketNo: docket,
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
        bagCode: bagCodeWorkingController.text.trim(),
      );
      OutboundUiFeedback.apply(
        target: lastResponseText,
        response: r,
        feature: 'Bagging',
      );
      r.when(
        success: (data) {
          final report = BaggingReport.fromDynamic(data);
          baggingReportData.value = report;
          final summary = report.summaryLines;
          if (summary.isNotEmpty) {
            lastResponseText.value = summary.join('\n');
          }
        },
        error: (_) {},
      );
    } finally {
      isBusy.value = false;
    }
  }

  void openBagDetailPage() {
    final code = bagCodeWorkingController.text.trim();
    if (code.isEmpty) {
      Get.snackbar('Bagging', 'Enter or scan bag code');
      return;
    }
    Get.toNamed(
      Routes.OUTBOUND_REMOTE_DETAIL,
      arguments: {'kind': 'bag', 'id': code},
    );
  }
}
