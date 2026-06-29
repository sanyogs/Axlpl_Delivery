import 'dart:io';

import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/models/invoice_upload_result_model.dart';
import 'package:axlpl_delivery/app/data/models/tracking_model.dart';
import 'package:axlpl_delivery/app/modules/pickdup_delivery_details/invoice_attachment_state.dart';
import 'package:axlpl_delivery/app/data/models/transtion_history_model.dart';
import 'package:axlpl_delivery/app/data/models/negative_status_model.dart';
import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/tracking_repo.dart';
import 'package:axlpl_delivery/common_widget/common_tow_btn_dialog.dart';
import 'package:axlpl_delivery/utils/image_compress_util.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ Added imports for status feature
import 'package:axlpl_delivery/app/data/models/status_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/delivery_repo.dart';

class StatusUpdateResult {
  final bool isSuccess;
  final String message;

  const StatusUpdateResult({
    required this.isSuccess,
    required this.message,
  });
}

class RunningDeliveryDetailsController extends GetxController {
  var currentStep = 0.obs;
  final TrackingRepo repo = TrackingRepo();
  final shipmentDetail = Rxn<ShipmentDetails>();

  var trackingStatus = <dynamic>[].obs;
  var senderData = <dynamic>[].obs;
  var receiverData = <dynamic>[].obs;
  var cashCollData = <CashLog>[].obs;

  var imageFile = Rx<File?>(null);
  var isTrackingLoading = Status.initial.obs;
  var isInvoiceUpload = Status.initial.obs;
  var isInvoiceDelete = Status.initial.obs;
  final message = ''.obs;
  var imageMap = <String, List<File>>{}.obs;
  final invoiceFileIdCache = <String, Map<String, String>>{}.obs;
  final hadMultiInvoiceFiles = <String, bool>{}.obs;
  final invoiceAttachmentsRevision = 0.obs;
  final _pendingUploadInvoiceFiles = <String, List<ShipmentInvoiceFile>>{};

  static const int maxInvoiceAttachments =
      InvoiceAttachmentState.maxInvoiceAttachments;

  final DeliveryRepo _deliveryRepo = DeliveryRepo();

  RxList<StatusModel> statusList = <StatusModel>[].obs;
  Rx<StatusModel?> selectedStatus = Rx<StatusModel?>(null);
  RxBool isStatusUpdating = false.obs;
  RxList<NegativeStatusModel> negativeStatusList = <NegativeStatusModel>[].obs;
  Rx<NegativeStatusModel?> selectedNegativeStatus =
      Rx<NegativeStatusModel?>(null);
  RxBool isNegative = false.obs;
  RxBool isNegativeStatusLoading = false.obs;
  final TextEditingController negativeRemarkController =
      TextEditingController();
  final TextEditingController receiverNameController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    negativeRemarkController.dispose();
    receiverNameController.dispose();
    super.onClose();
  }

  // --------------------------------------------------------------------------
  // 🔹 Local utility helpers
  // --------------------------------------------------------------------------
  List<String> resolveUploadedInvoiceUrls({
    required String shipmentId,
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) {
    return resolveUploadedInvoiceFiles(
      shipmentId: shipmentId,
      invoicePath: invoicePath,
      invoiceFile: invoiceFile,
      invoiceFiles: invoiceFiles,
    )
        .map((file) => file.resolvedUrl(invoicePath))
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
  }

  List<ShipmentInvoiceFile> resolveUploadedInvoiceFiles({
    required String shipmentId,
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) {
    final out = <ShipmentInvoiceFile>[];
    final seen = <String>{};

    void add(ShipmentInvoiceFile raw) {
      final enriched = _enrichInvoiceFile(shipmentId, raw);
      final url = enriched.resolvedUrl(invoicePath);
      if (url.isEmpty) return;
      final key = enriched.fileName?.trim().isNotEmpty == true
          ? enriched.fileName!.trim()
          : url;
      if (seen.contains(key)) return;
      seen.add(key);
      out.add(enriched);
    }

    final fromList = invoiceFiles ?? const <ShipmentInvoiceFile>[];
    for (final file in fromList) {
      if (file.resolvedUrl(invoicePath).isNotEmpty) add(file);
    }

    final suppressLegacy = fromList.isEmpty &&
        hadMultiInvoiceFiles[shipmentId] == true;
    if (fromList.isEmpty && !suppressLegacy) {
      final legacyUrls = InvoiceAttachmentState.uploadedInvoiceUrls(
        invoicePath: invoicePath,
        invoiceFile: invoiceFile,
      );
      for (final url in legacyUrls) {
        final name = url.split('/').where((part) => part.isNotEmpty).last;
        add(ShipmentInvoiceFile(fileName: name, fileUrl: url));
      }
    } else if (fromList.isNotEmpty && invoiceFile != null) {
      final legacyCount =
          InvoiceAttachmentState.uploadedCountFromInvoiceFile(invoiceFile);
      if (legacyCount > fromList.length) {
        final legacyUrls = InvoiceAttachmentState.uploadedInvoiceUrls(
          invoicePath: invoicePath,
          invoiceFile: invoiceFile,
        );
        for (final url in legacyUrls) {
          final name = url.split('/').where((part) => part.isNotEmpty).last;
          add(ShipmentInvoiceFile(fileName: name, fileUrl: url));
        }
      }
    }

    return out;
  }

  ShipmentInvoiceFile _enrichInvoiceFile(
    String shipmentId,
    ShipmentInvoiceFile file,
  ) {
    if (file.canDelete) return file;
    final name = file.fileName?.trim();
    if (name == null || name.isEmpty) return file;
    final cached = invoiceFileIdCache[shipmentId]?[name];
    if (cached == null || cached.isEmpty) return file;
    return ShipmentInvoiceFile(
      id: cached,
      fileName: file.fileName,
      originalName: file.originalName,
      fileUrl: file.fileUrl,
    );
  }

  void _notifyInvoiceUiChanged() {
    invoiceAttachmentsRevision.value++;
    shipmentDetail.refresh();
    invoiceFileIdCache.refresh();
    hadMultiInvoiceFiles.refresh();
    imageMap.refresh();
  }

  void _syncInvoiceAttachmentsFromServer(
    String shipmentId,
    ShipmentDetails? details,
  ) {
    final id = shipmentId.trim();
    if (id.isEmpty || details == null) return;

    final files = details.invoiceFiles;
    if (files == null) {
      // Legacy track response — show `invoice_file` until server sends `invoice_files`.
      hadMultiInvoiceFiles.remove(id);
      hadMultiInvoiceFiles.refresh();
      return;
    }

    // `invoice_files` present (even empty) => multi-invoice API; ignore stale legacy.
    hadMultiInvoiceFiles[id] = true;
    final cache = invoiceFileIdCache.putIfAbsent(id, () => {});
    final activeNames = <String>{};
    for (final file in files) {
      final fileId = file.id?.trim();
      final name = file.fileName?.trim();
      if (name != null && name.isNotEmpty) {
        activeNames.add(name);
      }
      if (fileId != null &&
          fileId.isNotEmpty &&
          name != null &&
          name.isNotEmpty) {
        cache[name] = fileId;
      }
    }
    cache.removeWhere((name, _) => !activeNames.contains(name));
    invoiceFileIdCache.refresh();
    hadMultiInvoiceFiles.refresh();
  }

  /// Re-fetch tracking details after upload/delete so attachments match the server.
  Future<void> refreshTrackingDetailsAfterInvoiceAction(
    String shipmentID, {
    List<ShipmentInvoiceFile>? ensureFiles,
  }) async {
    final id = shipmentID.trim();
    if (ensureFiles != null && ensureFiles.isNotEmpty) {
      _pendingUploadInvoiceFiles[id] = ensureFiles;
    }
    await fetchTrackingData(shipmentID, silent: true);
  }

  void _cacheInvoiceFileId(
    String shipmentId,
    String fileName,
    String fileId,
  ) {
    final sid = shipmentId.trim();
    final name = fileName.trim();
    final id = fileId.trim();
    if (sid.isEmpty || name.isEmpty || id.isEmpty) return;
    final cache = invoiceFileIdCache.putIfAbsent(sid, () => {});
    cache[name] = id;
    invoiceFileIdCache.refresh();
  }

  void _cacheInvoiceFileIdsFromFiles(
    String shipmentId,
    Iterable<ShipmentInvoiceFile> files,
  ) {
    for (final file in files) {
      final name = file.fileName?.trim();
      final id = file.id?.trim();
      if (name == null || name.isEmpty || id == null || id.isEmpty) continue;
      _cacheInvoiceFileId(shipmentId, name, id);
    }
  }

  void _forgetCachedInvoiceFile(String shipmentId, ShipmentInvoiceFile file) {
    final id = shipmentId.trim();
    final name = file.fileName?.trim();
    if (id.isEmpty || name == null || name.isEmpty) return;
    invoiceFileIdCache[id]?.remove(name);
    invoiceFileIdCache.refresh();
  }

  void _mergeUploadedInvoiceFilesIntoShipmentDetails(
    String shipmentId,
    List<ShipmentInvoiceFile> uploadedFiles,
  ) {
    if (uploadedFiles.isEmpty) return;
    final details = shipmentDetail.value;
    if (details == null) return;

    final invoicePath = details.invoicePath;
    final existing = List<ShipmentInvoiceFile>.from(details.invoiceFiles ?? []);
    final seen = <String>{
      for (final file in existing)
        if (file.fileName?.trim().isNotEmpty == true) file.fileName!.trim(),
    };

    for (final uploaded in uploadedFiles) {
      final name = uploaded.fileName?.trim();
      if (name == null || name.isEmpty || seen.contains(name)) continue;
      seen.add(name);
      final url = uploaded.resolvedUrl(invoicePath);
      existing.add(
        url.isNotEmpty
            ? ShipmentInvoiceFile(
                id: uploaded.id,
                fileName: name,
                originalName: uploaded.originalName,
                fileUrl: uploaded.fileUrl?.trim().isNotEmpty == true
                    ? uploaded.fileUrl
                    : url,
              )
            : uploaded,
      );
    }

    details.invoiceFiles = existing;
    details.invoiceFile = existing
        .map((file) => file.fileName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .join(',');
    if (existing.isNotEmpty) {
      hadMultiInvoiceFiles[shipmentId.trim()] = true;
    }
    _cacheInvoiceFileIdsFromFiles(shipmentId, existing);
    _notifyInvoiceUiChanged();
  }

  List<ShipmentInvoiceFile> _resolveUploadedFilesFromResult(
    InvoiceUploadResult result,
    List<File> localFiles,
  ) {
    final out = List<ShipmentInvoiceFile>.from(result.uploadedInvoiceFiles);
    final seen = <String>{
      for (final file in out)
        if (file.fileName?.trim().isNotEmpty == true) file.fileName!.trim(),
    };

    final expectedCount = result.totalFilesUploaded > 0
        ? result.totalFilesUploaded
        : localFiles.length;

    if (out.length < expectedCount) {
      for (final file in localFiles) {
        if (out.length >= expectedCount) break;
        final name = _localFileName(file);
        if (name.isEmpty || seen.contains(name)) continue;
        seen.add(name);
        out.add(ShipmentInvoiceFile(fileName: name));
      }
    }

    return out;
  }

  String _localFileName(File file) {
    final segments = file.uri.pathSegments;
    if (segments.isNotEmpty) return segments.last;
    final parts = file.path.split(Platform.pathSeparator);
    return parts.isNotEmpty ? parts.last : file.path;
  }

  void _removeUploadedInvoiceFromShipmentDetails(
    String shipmentId,
    ShipmentInvoiceFile file, {
    String? deletedFileName,
  }) {
    final details = shipmentDetail.value;
    if (details == null) return;

    final targetName = (deletedFileName ?? file.fileName)?.trim();
    final targetUrl = file.resolvedUrl(details.invoicePath);
    final remaining = (details.invoiceFiles ?? const <ShipmentInvoiceFile>[])
        .where((candidate) {
          final name = candidate.fileName?.trim();
          if (targetName != null &&
              targetName.isNotEmpty &&
              name == targetName) {
            return false;
          }
          if (targetUrl.isNotEmpty &&
              candidate.resolvedUrl(details.invoicePath) == targetUrl) {
            return false;
          }
          return true;
        })
        .toList(growable: false);

    details.invoiceFiles = remaining;
    details.invoiceFile = remaining
        .map((item) => item.fileName?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .join(',');

    _forgetCachedInvoiceFile(shipmentId, file);
    _notifyInvoiceUiChanged();
  }

  bool _invoiceFilesMatch(ShipmentInvoiceFile a, ShipmentInvoiceFile b) {
    final aName = a.fileName?.trim();
    final bName = b.fileName?.trim();
    if (aName != null && aName.isNotEmpty && aName == bName) return true;
    final aOriginal = a.originalName?.trim();
    final bOriginal = b.originalName?.trim();
    if (aOriginal != null &&
        aOriginal.isNotEmpty &&
        aOriginal == bOriginal) {
      return true;
    }
    return false;
  }

  Future<String?> _resolveInvoiceFileIdForDelete({
    required String shipmentID,
    required ShipmentInvoiceFile file,
  }) async {
    final direct = file.id?.trim();
    if (direct != null && direct.isNotEmpty) return direct;

    final enriched = _enrichInvoiceFile(shipmentID, file);
    final cached = enriched.id?.trim();
    if (cached != null && cached.isNotEmpty) return cached;

    final name = file.fileName?.trim();
    if (name != null && name.isNotEmpty) {
      final fromCache = invoiceFileIdCache[shipmentID.trim()]?[name]?.trim();
      if (fromCache != null && fromCache.isNotEmpty) return fromCache;
    }

    final details = shipmentDetail.value;
    final directFromDetails = _findInvoiceFileIdInDetails(details, file);
    if (directFromDetails != null && directFromDetails.isNotEmpty) {
      return directFromDetails;
    }

    await fetchTrackingData(shipmentID, silent: true);
    final refreshedDetails = shipmentDetail.value;
    final fromServer = _findInvoiceFileIdInDetails(refreshedDetails, file);
    if (fromServer != null && fromServer.isNotEmpty) return fromServer;

    final refreshed = resolveUploadedInvoiceFiles(
      shipmentId: shipmentID,
      invoicePath: refreshedDetails?.invoicePath,
      invoiceFile: refreshedDetails?.invoiceFile,
      invoiceFiles: refreshedDetails?.invoiceFiles,
    );
    final targetName = file.fileName?.trim();
    final targetOriginal = file.originalName?.trim();
    final targetUrl = file.resolvedUrl(refreshedDetails?.invoicePath);
    for (final candidate in refreshed) {
      final candidateId = candidate.id?.trim();
      if (candidateId == null || candidateId.isEmpty) continue;
      if (_invoiceFilesMatch(candidate, file)) {
        return candidateId;
      }
      final name = candidate.fileName?.trim();
      if (targetName != null &&
          targetName.isNotEmpty &&
          name == targetName) {
        return candidateId;
      }
      if (targetOriginal != null &&
          targetOriginal.isNotEmpty &&
          candidate.originalName?.trim() == targetOriginal) {
        return candidateId;
      }
      if (targetUrl.isNotEmpty &&
          candidate.resolvedUrl(refreshedDetails?.invoicePath) == targetUrl) {
        return candidateId;
      }
    }
    return null;
  }

  String? _findInvoiceFileIdInDetails(
    ShipmentDetails? details,
    ShipmentInvoiceFile file,
  ) {
    if (details == null) return null;
    final files = details.invoiceFiles;
    if (files == null || files.isEmpty) return null;

    for (final candidate in files) {
      final candidateId = candidate.id?.trim();
      if (candidateId == null || candidateId.isEmpty) continue;
      if (_invoiceFilesMatch(candidate, file)) return candidateId;

      final targetUrl = file.resolvedUrl(details.invoicePath);
      if (targetUrl.isNotEmpty &&
          candidate.resolvedUrl(details.invoicePath) == targetUrl) {
        return candidateId;
      }
    }
    return null;
  }

  void addImages(
    String shipmentId,
    List<File> files, {
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) {
    if (files.isEmpty) return;
    final current = List<File>.from(imageMap[shipmentId] ?? const []);
    final remaining = remainingAttachmentSlots(
      shipmentId,
      invoicePath: invoicePath,
      invoiceFile: invoiceFile,
      invoiceFiles: invoiceFiles,
    );
    final merged = InvoiceAttachmentState.appendFiles(
      current,
      files.take(remaining).toList(growable: false),
    );
    if (merged.length == current.length) {
      _showAttachmentLimitSnack();
      return;
    }
    if (merged.length - current.length < files.length) {
      _showAttachmentLimitSnack(partial: true);
    }
    imageMap[shipmentId] = merged;
    imageMap.refresh();
  }

  void addImage(
    String shipmentId,
    File file, {
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) {
    addImages(
      shipmentId,
      [file],
      invoicePath: invoicePath,
      invoiceFile: invoiceFile,
      invoiceFiles: invoiceFiles,
    );
  }

  void removeImage(String shipmentId, int index) {
    final current = imageMap[shipmentId];
    if (current == null || index < 0 || index >= current.length) return;
    imageMap[shipmentId] = InvoiceAttachmentState.removeAt(current, index);
    if (imageMap[shipmentId]!.isEmpty) {
      imageMap.remove(shipmentId);
    }
    imageMap.refresh();
  }

  void clearImages(String shipmentId) {
    imageMap.remove(shipmentId);
    imageMap.refresh();
  }

  List<File> getImages(String shipmentId) {
    return List<File>.from(imageMap[shipmentId] ?? const []);
  }

  int pendingAttachmentCount(String shipmentId) => getImages(shipmentId).length;

  int uploadedAttachmentCount({
    required String shipmentId,
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) =>
      resolveUploadedInvoiceUrls(
        shipmentId: shipmentId,
        invoicePath: invoicePath,
        invoiceFile: invoiceFile,
        invoiceFiles: invoiceFiles,
      ).length;

  int totalAttachmentCount(
    String shipmentId, {
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) =>
      InvoiceAttachmentState.totalCount(
        uploadedCount: uploadedAttachmentCount(
          shipmentId: shipmentId,
          invoicePath: invoicePath,
          invoiceFile: invoiceFile,
          invoiceFiles: invoiceFiles,
        ),
        pendingCount: pendingAttachmentCount(shipmentId),
      );

  int remainingAttachmentSlots(
    String shipmentId, {
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) =>
      InvoiceAttachmentState.remainingSlots(
        totalAttachmentCount(
          shipmentId,
          invoicePath: invoicePath,
          invoiceFile: invoiceFile,
          invoiceFiles: invoiceFiles,
        ),
      );

  bool canAddMoreAttachments(
    String shipmentId, {
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) =>
      InvoiceAttachmentState.canAddMore(
        totalAttachmentCount(
          shipmentId,
          invoicePath: invoicePath,
          invoiceFile: invoiceFile,
          invoiceFiles: invoiceFiles,
        ),
      );

  void _showAttachmentLimitSnack({bool partial = false}) {
    final msg = partial
        ? 'Only ${maxInvoiceAttachments} invoice files allowed. Extra files were skipped.'
        : 'You can attach up to $maxInvoiceAttachments invoice files.';
    Get.snackbar(
      'Invoice',
      msg,
      backgroundColor: themes.redColor,
      colorText: themes.whiteColor,
    );
  }

  List<CashLog> get cashCollectionData => cashCollData;
  bool get hasCashCollectionData => cashCollData.isNotEmpty;

  double get totalCashAmount {
    return cashCollData.fold(0.0, (sum, cash) {
      try {
        return sum +
            (double.tryParse(cash.cashamount?.toString() ?? '0') ?? 0.0);
      } catch (e) {
        return sum;
      }
    });
  }

  Future<void> makingPhoneCall(String phoneNo) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNo);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> pickImagesFromGallery(
    String shipmentId, {
    String? invoicePath,
    dynamic invoiceFile,
    List<ShipmentInvoiceFile>? invoiceFiles,
  }) async {
    final remaining = remainingAttachmentSlots(
      shipmentId,
      invoicePath: invoicePath,
      invoiceFile: invoiceFile,
      invoiceFiles: invoiceFiles,
    );
    if (remaining <= 0) {
      _showAttachmentLimitSnack();
      return;
    }
    try {
      final picker = ImagePicker();
      final List<XFile> pickedFiles;
      if (remaining == 1) {
        final single = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: ImageCompressUtil.defaultQuality,
          maxWidth: ImageCompressUtil.defaultMaxDimension.toDouble(),
          maxHeight: ImageCompressUtil.defaultMaxDimension.toDouble(),
        );
        pickedFiles = single == null ? const [] : [single];
      } else {
        pickedFiles = await picker.pickMultiImage(
          imageQuality: ImageCompressUtil.defaultQuality,
          maxWidth: ImageCompressUtil.defaultMaxDimension.toDouble(),
          maxHeight: ImageCompressUtil.defaultMaxDimension.toDouble(),
          limit: remaining.clamp(1, maxInvoiceAttachments),
        );
      }
      if (pickedFiles.isEmpty) return;

      final files = <File>[];
      for (final picked in pickedFiles.take(remaining)) {
        final file = File(picked.path);
        if (await file.exists()) {
          files.add(await ImageCompressUtil.compressForUpload(file));
        }
      }
      if (files.isEmpty) {
        Get.snackbar(
          "Error",
          "Unable to read the selected images.",
          backgroundColor: themes.redColor,
          colorText: themes.whiteColor,
        );
        return;
      }
      addImages(
        shipmentId,
        files,
        invoicePath: invoicePath,
        invoiceFile: invoiceFile,
        invoiceFiles: invoiceFiles,
      );
    } on PlatformException catch (e) {
      _handlePickError(e);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unable to pick images: $e",
        backgroundColor: themes.redColor,
        colorText: themes.whiteColor,
      );
    }
  }

  Future<void> pickImage(
      ImageSource source, void Function(File) onPicked) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: ImageCompressUtil.defaultQuality,
        maxWidth: ImageCompressUtil.defaultMaxDimension.toDouble(),
        maxHeight: ImageCompressUtil.defaultMaxDimension.toDouble(),
      );

      if (pickedFile == null) return;

      final file = await ImageCompressUtil.compressForUpload(
        File(pickedFile.path),
      );
      if (!await file.exists()) {
        Get.snackbar(
          "Error",
          "Unable to read the selected image.",
          backgroundColor: themes.redColor,
          colorText: themes.whiteColor,
        );
        return;
      }

      onPicked(file);
    } on PlatformException catch (e) {
      _handlePickError(e);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unable to pick image: $e",
        backgroundColor: themes.redColor,
        colorText: themes.whiteColor,
      );
    }
  }

  void _handlePickError(PlatformException e) {
    final code = e.code.toLowerCase();
    final isPermissionIssue = code.contains('permission') ||
        code.contains('denied') ||
        code.contains('camera_access_denied') ||
        code.contains('photo_access_denied');

    Get.snackbar(
      isPermissionIssue ? "Permission Required" : "Error",
      isPermissionIssue
          ? "Please allow camera/photos permission to add the invoice."
          : (e.message ?? "Unable to pick image."),
      backgroundColor: themes.redColor,
      colorText: themes.whiteColor,
    );
  }

  // --------------------------------------------------------------------------
  // 🔹 Tracking Fetch
  // --------------------------------------------------------------------------
  void _applyTrackingPayload(String shipmentID, List<Tracking> trackingList) {
    List<TrackingStatus> trackingStatusList = [];
    List<ErData> senderDataList = [];
    List<ErData> receiverDataList = [];
    List<CashLog> cashCollList = [];
    ShipmentDetails? shipmentDetails;

    for (var item in trackingList) {
      if (item.trackingStatus != null && item.trackingStatus!.isNotEmpty) {
        trackingStatusList.addAll(item.trackingStatus!);
      }
      if (item.senderData != null) senderDataList.add(item.senderData!);
      if (item.receiverData != null) receiverDataList.add(item.receiverData!);
      if (item.cashLog != null && item.cashLog!.isNotEmpty) {
        cashCollList.addAll(item.cashLog!);
      }
      if (shipmentDetails == null && item.shipmentDetails != null) {
        shipmentDetails = item.shipmentDetails;
      }
    }

    trackingStatus.value = trackingStatusList;
    senderData.value = senderDataList;
    receiverData.value = receiverDataList;
    cashCollData.value = cashCollList;
    shipmentDetail.value = shipmentDetails;
    _syncInvoiceAttachmentsFromServer(shipmentID, shipmentDetails);

    final pending = _pendingUploadInvoiceFiles.remove(shipmentID.trim());
    if (pending != null &&
        pending.isNotEmpty &&
        shipmentDetails != null) {
      _mergeUploadedInvoiceFilesIntoShipmentDetails(shipmentID, pending);
    }

    Utils().logInfo("""
        Tracking Data Loaded:
        - Status Events: ${trackingStatusList.length}
        - Sender Data: ${senderDataList.length}
        - Receiver Data: ${receiverDataList.length}
        - Cash Collection Data: ${cashCollList.length}
        - Shipment Details: ${shipmentDetails != null ? 'Available' : 'Not Available'}
        - Invoice files: ${shipmentDetails?.invoiceFiles?.length ?? 'legacy'}
        """);
  }

  Future<void> fetchTrackingData(
    String shipmentID, {
    bool silent = false,
  }) async {
    if (!silent) {
      isTrackingLoading.value = Status.loading;
    }
    try {
      final trackingData = await repo.trackingRepo(shipmentID);
      final trackingList = trackingData?.tracking ?? [];

      if (trackingList.isNotEmpty) {
        _applyTrackingPayload(shipmentID, trackingList);
        if (!silent) {
          isTrackingLoading.value = Status.success;
        } else {
          _notifyInvoiceUiChanged();
        }
      } else {
        if (!silent) {
          _clearAllData();
          isTrackingLoading.value = Status.error;
          Utils().logInfo("No tracking data found for shipment: $shipmentID");
        } else {
          Utils().logInfo(
            "Silent refresh: no tracking data for shipment: $shipmentID",
          );
        }
      }
    } catch (e) {
      if (!silent) {
        _clearAllData();
        isTrackingLoading.value = Status.error;
      }
      Utils().logError("Failed to fetch tracking data: ${e.toString()}");
    }
  }

  // --------------------------------------------------------------------------
  // 🔹 Invoice Upload
  // --------------------------------------------------------------------------
  Future<void> uploadInvoice({
    required String shipmentID,
    required List<File> files,
  }) async {
    try {
      final existing = <File>[];
      for (final file in files) {
        if (await file.exists()) existing.add(file);
      }
      if (existing.isEmpty) {
        Get.snackbar(
          "Error",
          "Selected invoice files not found.",
          backgroundColor: themes.redColor,
          colorText: themes.whiteColor,
        );
        return;
      }

      isInvoiceUpload.value = Status.loading;
      message.value = '';

      final compressed = await ImageCompressUtil.compressAllForUpload(existing);
      final result = await repo.uploadInvoiceRepo(shipmentID, compressed);
      if (result.success) {
        final uploadedCount = result.totalFilesUploaded > 0
            ? result.totalFilesUploaded
            : compressed.length;
        final uploadedFiles = _resolveUploadedFilesFromResult(
          result,
          compressed,
        );
        message.value = result.message?.trim().isNotEmpty == true
            ? result.message!.trim()
            : uploadedCount > 1
                ? '$uploadedCount invoices uploaded successfully'
                : 'Invoice uploaded successfully';
        clearImages(shipmentID);
        _mergeUploadedInvoiceFilesIntoShipmentDetails(shipmentID, uploadedFiles);
        _cacheInvoiceFileIdsFromFiles(shipmentID, result.uploadedInvoiceFiles);
        Get.snackbar("Success", message.value,
            backgroundColor: themes.darkCyanBlue, colorText: themes.whiteColor);
        await refreshTrackingDetailsAfterInvoiceAction(
          shipmentID,
          ensureFiles: uploadedFiles,
        );
        isInvoiceUpload.value = Status.initial;
      } else {
        isInvoiceUpload.value = Status.error;
        message.value = result.message ?? repo.apiMessage ?? 'Upload failed';
        Get.snackbar("Error", message.value,
            backgroundColor: themes.redColor, colorText: themes.whiteColor);
      }
    } catch (e) {
      isInvoiceUpload.value = Status.error;
      message.value = 'Unexpected error: $e';
      Get.snackbar("Error", message.value,
          backgroundColor: themes.redColor, colorText: themes.whiteColor);
    } finally {
      if (isInvoiceUpload.value == Status.loading) {
        isInvoiceUpload.value = Status.initial;
      }
    }
  }

  void confirmDeleteUploadedInvoice({
    required String shipmentID,
    required ShipmentInvoiceFile file,
  }) {
    if (isInvoiceDelete.value == Status.loading ||
        isInvoiceUpload.value == Status.loading) {
      return;
    }

    final displayName = file.originalName?.trim().isNotEmpty == true
        ? file.originalName!.trim()
        : (file.fileName?.trim().isNotEmpty == true
            ? file.fileName!.trim()
            : 'this invoice');

    commonDialog(
      'Delete Invoice',
      'Are you sure you want to delete $displayName?',
      'Delete',
      'Cancel',
      () async {
        try {
          final details = shipmentDetail.value;
          final resolvedFiles = resolveUploadedInvoiceFiles(
            shipmentId: shipmentID,
            invoicePath: details?.invoicePath,
            invoiceFile: details?.invoiceFile,
            invoiceFiles: details?.invoiceFiles,
          );
          final target = resolvedFiles.firstWhere(
            (candidate) => _invoiceFilesMatch(candidate, file),
            orElse: () => _enrichInvoiceFile(shipmentID, file),
          );

          final invoiceFileId = await _resolveInvoiceFileIdForDelete(
            shipmentID: shipmentID,
            file: target,
          );
          final fileName = target.fileName?.trim();
          if ((invoiceFileId == null || invoiceFileId.isEmpty) &&
              (fileName == null || fileName.isEmpty)) {
            await refreshTrackingDetailsAfterInvoiceAction(shipmentID);
            final retryId = await _resolveInvoiceFileIdForDelete(
              shipmentID: shipmentID,
              file: target,
            );
            if ((retryId == null || retryId.isEmpty) &&
                (fileName == null || fileName.isEmpty)) {
              Get.snackbar(
                'Invoice',
                'Unable to delete this attachment. Please refresh and try again.',
                backgroundColor: themes.redColor,
                colorText: themes.whiteColor,
              );
              return;
            }
            await deleteUploadedInvoice(
              shipmentID: shipmentID,
              file: target,
              invoiceFileId: retryId,
            );
            return;
          }
          await deleteUploadedInvoice(
            shipmentID: shipmentID,
            file: target,
            invoiceFileId: invoiceFileId,
          );
        } catch (e) {
          Get.snackbar(
            'Invoice',
            'Delete failed: $e',
            backgroundColor: themes.redColor,
            colorText: themes.whiteColor,
          );
        }
      },
      icon: Icons.delete_outline,
      iconColor: themes.redColor,
    );
  }

  Future<void> deleteUploadedInvoice({
    required String shipmentID,
    required ShipmentInvoiceFile file,
    String? invoiceFileId,
  }) async {
    try {
      isInvoiceDelete.value = Status.loading;
      message.value = '';

      final result = await repo.deleteShipmentInvoiceFileRepo(
        invoiceFileId: invoiceFileId,
        fileName: file.fileName,
      );
      if (result.success) {
        _removeUploadedInvoiceFromShipmentDetails(
          shipmentID,
          file,
          deletedFileName: result.fileName ?? file.fileName,
        );
        message.value = result.message?.trim().isNotEmpty == true
            ? result.message!.trim()
            : 'Invoice file deleted successfully';
        Get.snackbar(
          'Success',
          message.value,
          backgroundColor: themes.darkCyanBlue,
          colorText: themes.whiteColor,
        );
        await refreshTrackingDetailsAfterInvoiceAction(shipmentID);
        isInvoiceDelete.value = Status.initial;
      } else {
        isInvoiceDelete.value = Status.error;
        message.value = result.message ?? repo.apiMessage ?? 'Delete failed';
        Get.snackbar(
          'Error',
          message.value,
          backgroundColor: themes.redColor,
          colorText: themes.whiteColor,
        );
      }
    } catch (e) {
      isInvoiceDelete.value = Status.error;
      message.value = 'Unexpected error: $e';
      Get.snackbar(
        'Error',
        message.value,
        backgroundColor: themes.redColor,
        colorText: themes.whiteColor,
      );
    } finally {
      if (isInvoiceDelete.value == Status.loading) {
        isInvoiceDelete.value = Status.initial;
      }
    }
  }

  void _clearAllData() {
    trackingStatus.clear();
    senderData.clear();
    receiverData.clear();
    cashCollData.clear();
    shipmentDetail.value = null;
  }

  // --------------------------------------------------------------------------
  // 🔹 Status Dropdown + Update Logic
  // --------------------------------------------------------------------------
  Future<void> getAllStatuses() async {
    try {
      Utils().logInfo('Fetching statuses...');
      final list = await _deliveryRepo.fetchStatuses();
      if (list != null && list.isNotEmpty) {
        statusList.value = list;
        Utils().logInfo('Statuses loaded: ${list.length}');
      } else {
        statusList.clear();
        Utils().logInfo('No statuses returned.');
      }
    } catch (e) {
      Utils().logError('Error fetching statuses: $e');
    }
  }

  Future<void> getNegativeStatuses({StatusModel? status}) async {
    try {
      isNegativeStatusLoading.value = true;
      negativeStatusList.clear();
      selectedNegativeStatus.value = null;
      Utils().logInfo('Fetching negative statuses...');
      final effectiveStatus = status ?? selectedStatus.value;
      final statusText = effectiveStatus?.status?.trim();
      final statusId = effectiveStatus?.id?.trim();
      final list = await _deliveryRepo.fetchNegativeStatuses(
        status:
            (statusText != null && statusText.isNotEmpty) ? statusText : null,
        statusId: (statusId != null && statusId.isNotEmpty) ? statusId : null,
      );
      if (list.isNotEmpty) {
        negativeStatusList.value = list;
        Utils().logInfo('Negative statuses loaded: ${list.length}');
      } else {
        negativeStatusList.clear();
        Utils().logInfo('No negative statuses returned.');
      }
    } catch (e) {
      Utils().logError('Error fetching negative statuses: $e');
      negativeStatusList.clear();
    } finally {
      isNegativeStatusLoading.value = false;
    }
  }

  String _resolveReceiverName() {
    if (receiverData.isNotEmpty) {
      final first = receiverData.first;
      if (first is ErData) {
        return first.receiverName?.trim().isNotEmpty == true
            ? first.receiverName!.trim()
            : (first.companyName ?? '').trim();
      }
      if (first is Map) {
        final name = first['receiver_name']?.toString().trim();
        if (name != null && name.isNotEmpty) return name;
        final company = first['company_name']?.toString().trim();
        if (company != null && company.isNotEmpty) return company;
      }
    }
    return '';
  }

  void setSelectedStatus(StatusModel? status) {
    selectedStatus.value = status;
    final statusText = (status?.status ?? '').trim().toLowerCase();
    if (statusText == 'delivered' &&
        receiverNameController.text.trim().isEmpty) {
      receiverNameController.text = _resolveReceiverName();
    }
  }

  bool get isDeliveredSelected =>
      (selectedStatus.value?.status ?? '').trim().toLowerCase() == 'delivered';

  StatusUpdateResult? validateStatusSelection() {
    final selected = selectedStatus.value;
    if (selected == null) {
      return const StatusUpdateResult(
        isSuccess: false,
        message: 'Please select a status.',
      );
    }

    if (isNegative.value) {
      if (selectedNegativeStatus.value == null) {
        return const StatusUpdateResult(
          isSuccess: false,
          message: 'Please select a negative status.',
        );
      }
      if (negativeRemarkController.text.trim().isEmpty) {
        return const StatusUpdateResult(
          isSuccess: false,
          message: 'Please enter a remark.',
        );
      }
    }

    if (isDeliveredSelected && receiverNameController.text.trim().isEmpty) {
      return const StatusUpdateResult(
        isSuccess: false,
        message: 'Please enter receiver name.',
      );
    }

    return null;
  }

  Future<StatusUpdateResult> updateShipmentStatus(String shipmentId) async {
    final validationResult = validateStatusSelection();
    if (validationResult != null) {
      return validationResult;
    }

    final selected = selectedStatus.value;
    final statusText = (selected?.status ?? '').trim().toLowerCase();
    final isDelivered = statusText == 'delivered';

    isStatusUpdating.value = true;
    try {
      final remark = negativeRemarkController.text.trim();
      final receiverName = receiverNameController.text.trim();
      final result = await _deliveryRepo.updateShipmentStatusNewRepo(
        shipmentId: shipmentId,
        shipmentStatus: selected?.status ?? '',
        isNegative: isNegative.value,
        negativeStatus:
            isNegative.value ? selectedNegativeStatus.value?.apiValue : null,
        negativeRemark: remark.isNotEmpty ? remark : null,
        receiverName:
            isDelivered && receiverName.isNotEmpty ? receiverName : null,
      );

      if (result != null) {
        final isSuccess = result.status == "success";
        final message = (result.message ?? '').trim().isNotEmpty
            ? result.message!.trim()
            : 'No message returned from server.';
        if (isSuccess) {
          await fetchTrackingData(shipmentId);
        }
        return StatusUpdateResult(
          isSuccess: isSuccess,
          message: message,
        );
      }
      return const StatusUpdateResult(
        isSuccess: false,
        message: "No response returned from server.",
      );
    } catch (e) {
      return StatusUpdateResult(
        isSuccess: false,
        message: e.toString(),
      );
    } finally {
      isStatusUpdating.value = false;
    }
  }

  final role = ''.obs;

  Future<void> loadUserRole() async {
    if (role.value.isNotEmpty) return; // prevent reloading
    final userData = await LocalStorage().getUserLocalData();
    role.value = userData?.role ?? '';
  }
}
