import 'dart:io';

import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/models/stepper_model.dart';
import 'package:axlpl_delivery/app/data/models/tracking_model.dart';
import 'package:axlpl_delivery/app/data/models/transtion_history_model.dart';
import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/tracking_repo.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ Added imports for status feature
import 'package:axlpl_delivery/app/data/models/status_model.dart';
import 'package:axlpl_delivery/app/data/models/update_status_model.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/delivery_repo.dart';

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
  final message = ''.obs;
  var imageMap = <String, File>{}.obs;

  final DeliveryRepo _deliveryRepo = DeliveryRepo();

  RxList<StatusModel> statusList = <StatusModel>[].obs;
  Rx<StatusModel?> selectedStatus = Rx<StatusModel?>(null);
  RxBool isStatusUpdating = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  // --------------------------------------------------------------------------
  // 🔹 Local utility helpers
  // --------------------------------------------------------------------------
  void setImage(String shipmentId, File file) {
    imageMap[shipmentId] = file;
    imageMap.refresh();
  }

  void removeImage(String shipmentId) {
    imageMap.remove(shipmentId);
    imageMap.refresh();
  }

  File? getImage(String shipmentId) {
    return imageMap[shipmentId];
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

  Future<void> pickImage(ImageSource source, void Function(File) onPicked) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
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
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unable to pick image: $e",
        backgroundColor: themes.redColor,
        colorText: themes.whiteColor,
      );
    }
  }

  // --------------------------------------------------------------------------
  // 🔹 Tracking Fetch
  // --------------------------------------------------------------------------
  Future<void> fetchTrackingData(String shipmentID) async {
    isTrackingLoading.value = Status.loading;
    try {
      final trackingData = await repo.trackingRepo(shipmentID);
      final trackingList = trackingData?.tracking ?? [];

      if (trackingList.isNotEmpty) {
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
        isTrackingLoading.value = Status.success;

        Utils().logInfo("""
        Tracking Data Loaded:
        - Status Events: ${trackingStatusList.length}
        - Sender Data: ${senderDataList.length}
        - Receiver Data: ${receiverDataList.length}
        - Cash Collection Data: ${cashCollList.length}
        - Shipment Details: ${shipmentDetails != null ? 'Available' : 'Not Available'}
        """);
      } else {
        _clearAllData();
        isTrackingLoading.value = Status.error;
        Utils().logInfo("No tracking data found for shipment: $shipmentID");
      }
    } catch (e) {
      _clearAllData();
      isTrackingLoading.value = Status.error;
      Utils().logError("Failed to fetch tracking data: ${e.toString()}");
    }
  }

  // --------------------------------------------------------------------------
  // 🔹 Invoice Upload
  // --------------------------------------------------------------------------
  Future<void> uploadInvoice({
    required String shipmentID,
    required File file,
  }) async {
    try {
      if (!await file.exists()) {
        Get.snackbar(
          "Error",
          "Selected invoice file not found.",
          backgroundColor: themes.redColor,
          colorText: themes.whiteColor,
        );
        return;
      }

      isInvoiceUpload.value = Status.loading;
      message.value = '';

      final result = await repo.uploadInvoiceRepo(shipmentID, file);
      if (result) {
        isInvoiceUpload.value = Status.success;
        message.value = repo.apiMessage ?? 'Upload Invoice successful';
        Get.snackbar("Success", message.value,
            backgroundColor: themes.darkCyanBlue, colorText: themes.whiteColor);
        fetchTrackingData(shipmentID);
      } else {
        isInvoiceUpload.value = Status.error;
        message.value = repo.apiMessage ?? 'Upload failed';
        Get.snackbar("Error", message.value,
            backgroundColor: themes.redColor, colorText: themes.whiteColor);
      }
    } catch (e) {
      isInvoiceUpload.value = Status.error;
      message.value = 'Unexpected error: $e';
      Get.snackbar("Error", message.value,
          backgroundColor: themes.redColor, colorText: themes.whiteColor);
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

  Future<bool> updateShipmentStatus(String shipmentId) async {
    final selected = selectedStatus.value;
    if (selected == null) {
      Get.snackbar(
        "Error",
        "Please select a status",
        backgroundColor: themes.redColor,
        colorText: themes.whiteColor,
      );
      return false;
    }

    isStatusUpdating.value = true;
    try {
      final result = await _deliveryRepo.updateShipmentStatusRepo(
        shipmentId: shipmentId,
        shipmentStatus: selected.status ?? '',
      );

      if (result != null && result.status == "success") {
        Get.snackbar(
          "Success",
          result.message ?? 'Shipment status updated successfully.',
          backgroundColor: themes.darkCyanBlue,
          colorText: themes.whiteColor,
        );

        await fetchTrackingData(shipmentId);
        return true; // ✅ success
      } else {
        Get.snackbar(
          "Error",
          result?.message ?? 'Failed to update shipment status.',
          backgroundColor: themes.redColor,
          colorText: themes.whiteColor,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Error updating status: $e",
        backgroundColor: themes.redColor,
        colorText: themes.whiteColor,
      );
      return false;
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
