import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/bagging_report_pdf_generator.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';

/// Read-only bag details (`getbagdetails`) — separate from bagging edit session.
class BaggingDetailsController extends GetxController {
  BaggingDetailsController({OutboundRepository? repo})
      : _repo = repo ?? Get.find<OutboundRepository>();

  final OutboundRepository _repo;

  final detail = Rxn<BagDetail>();
  final isLoading = false.obs;
  final isPrinting = false.obs;
  final errorMessage = ''.obs;

  String? _bagRef;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      _bagRef = args['bagRef']?.toString().trim();
    }
    load();
  }

  @override
  void onClose() {
    detail.value = null;
    errorMessage.value = '';
    super.onClose();
  }

  Future<bool> load({String? bagRef}) async {
    final ref = bagRef?.trim() ?? _bagRef?.trim();
    if (ref == null || ref.isEmpty) {
      errorMessage.value = 'Bag reference is required.';
      return false;
    }
    _bagRef = ref;
    isLoading.value = true;
    errorMessage.value = '';
    detail.value = null;
    try {
      final r = await _repo.fetchBagDetails(ref);
      var ok = false;
      r.when(
        success: (data) {
          final parsed = BagDetail.fromDynamic(
            data,
            requestedBagCode: ref,
          );
          if (parsed.bagCode?.trim().isEmpty == true &&
              parsed.items.isEmpty &&
              parsed.metalSealNo?.trim().isEmpty == true) {
            errorMessage.value = 'Bag details not found in response.';
            return;
          }
          detail.value = parsed;
          ok = true;
        },
        error: (e) => errorMessage.value = e.message.trim(),
      );
      return ok;
    } finally {
      isLoading.value = false;
    }
  }

  /// Explicit edit entry — only from **Add More** on the details screen.
  Future<void> openBaggingToAddMore() async {
    final bag = detail.value;
    if (bag == null) return;
    final fetchRef = bag.bagCode?.trim().isNotEmpty == true
        ? bag.bagCode!.trim()
        : bag.metalSealNo?.trim() ?? _bagRef;
    if (!Get.isRegistered<OutboundBaggingController>()) return;
    final bagging = Get.find<OutboundBaggingController>();
    await bagging.openBagForEditing(bag, fetchRef: fetchRef);
    Get.until(
      (route) =>
          route.settings.name == Routes.OUTBOUND_BAGGING || route.isFirst,
    );
    if (Get.currentRoute != Routes.OUTBOUND_BAGGING) {
      await Get.toNamed(Routes.OUTBOUND_BAGGING);
    }
  }

  Future<void> printChallan() async {
    final bag = detail.value;
    final ref = bag?.bagCode?.trim().isNotEmpty == true
        ? bag!.bagCode!.trim()
        : bag?.metalSealNo?.trim() ?? _bagRef?.trim();
    if (ref == null || ref.isEmpty) {
      Get.snackbar('Bagging', 'Bagging number is required.');
      return;
    }

    isPrinting.value = true;
    try {
      final r = await _fetchBaggingReportForRef(ref);
      dynamic data;
      var failed = false;
      r.when(
        success: (value) => data = value,
        error: (e) {
          failed = true;
          Get.snackbar('Bagging', e.message);
        },
      );
      if (failed || data == null) return;

      final report = BaggingReport.fromDynamic(data);
      if ((report.bagCode == null || report.bagCode!.isEmpty) &&
          report.items.isEmpty) {
        Get.snackbar('Bagging', 'No bagging report data returned.');
        return;
      }
      final messengerName = await _messengerDisplayName();
      final createdBy = report.createdByLabel(messengerName);
      final path = await BaggingReportPdfGenerator.save(
        report: report,
        createdByDisplay: createdBy,
      );
      final msg = OutboundUiFeedback.serverMessageFromData(data)?.trim();
      final open = await OpenFile.open(path);
      if (open.type != ResultType.done) {
        Get.snackbar(
          'Bagging',
          msg?.isNotEmpty == true
              ? '$msg\nSaved: $path'
              : 'PDF saved: $path',
        );
        return;
      }
      Get.snackbar(
        'Bagging',
        msg?.isNotEmpty == true ? msg! : 'Bagging report PDF generated.',
      );
    } finally {
      isPrinting.value = false;
    }
  }

  Future<String?> _messengerDisplayName() async {
    final user = await LocalStorage().getUserLocalData();
    return user?.messangerdetail?.name?.trim();
  }

  Future<APIResponse<dynamic>> _fetchBaggingReportForRef(String ref) async {
    final trimmed = ref.trim();
    final first = await _repo.baggingReport(bagCode: trimmed);
    if (_baggingReportHasContent(first)) return first;

    if (OutboundApiParams.looksLikeBagCode(trimmed)) {
      return first;
    }

    final detailR = await _repo.fetchBagDetails(trimmed);
    BagDetail? bagDetail;
    detailR.when(
      success: (data) =>
          bagDetail = BagDetail.fromDynamic(data, requestedBagCode: trimmed),
      error: (_) {},
    );
    final resolved = bagDetail?.bagCode?.trim();
    if (resolved != null &&
        resolved.isNotEmpty &&
        resolved.toLowerCase() != trimmed.toLowerCase()) {
      final second = await _repo.baggingReport(bagCode: resolved);
      if (_baggingReportHasContent(second)) return second;
    }
    return first;
  }

  bool _baggingReportHasContent(APIResponse<dynamic> response) {
    var ok = false;
    response.when(
      success: (data) {
        final report = BaggingReport.fromDynamic(data);
        ok = (report.bagCode?.trim().isNotEmpty == true) ||
            report.items.isNotEmpty;
      },
      error: (_) => ok = false,
    );
    return ok;
  }
}
