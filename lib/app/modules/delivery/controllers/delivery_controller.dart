import 'dart:async';

import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/models/payment_mode_model.dart';
import 'package:axlpl_delivery/app/data/models/pickup_model.dart';
import 'package:axlpl_delivery/app/data/networking/api_client.dart';
import 'package:axlpl_delivery/app/data/networking/api_endpoint.dart';
import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/delivery_repo.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/pickup_repo.dart';
import 'package:axlpl_delivery/app/modules/history/controllers/history_controller.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DeliveryController extends GetxController {
  final pickupRepo = PickupRepo();
  final deliveryRepo = DeliveryRepo();
  final Dio dio = Dio();
  ApiClient apiClient = ApiClient();
  final historyController = Get.put(HistoryController());
  //TODO: Implement DeliveryController
  var isDeliveryLoading = Status.initial.obs;
  var isUploadDelivery = Status.initial.obs;
  var isOtpLoading = Status.initial.obs;
  final isOtpSent = false.obs;
  final otpStatusMessage = ''.obs;
  final submitStatusMessage = ''.obs;
  final isSubmitStatusError = false.obs;
  final currentUserId = ''.obs;
  RxInt isSelected = 0.obs;
  final secondsLeft = 0.obs; // 0 means no active timer
  final canResend = true.obs; // allowed when no timer running
  Timer? _resendTimer;
  static const int _cooldownSecs = 30;

  final deliveryList = <RunningDelivery>[].obs;
  final RxList<RunningDelivery> filteredDeliveryList = <RunningDelivery>[].obs;

  var subPaymentModes = <PaymentMode>[].obs;
  var selectedSubPaymentMode = Rxn<PaymentMode>();

  final Map<String, Rxn<PaymentMode>> selectedSubPaymentModes = {};

  Rxn<PaymentMode> getSelectedSubPaymentMode(String shipmentId) {
    return selectedSubPaymentModes.putIfAbsent(
        shipmentId, () => Rxn<PaymentMode>());
  }

  void setSelectedSubPaymentMode(String shipmentId, PaymentMode? mode) {
    getSelectedSubPaymentMode(shipmentId).value = mode;
  }

  void selectedContainer(int index) {
    isSelected.value = index;
  }

  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController chequeNumberController = TextEditingController();

  final Map<String, TextEditingController> amountControllers = {};
  final Map<String, TextEditingController> chequeControllers = {};
  final Map<String, TextEditingController> accountControllers = {};
  final Map<String, TextEditingController> onlineControllers = {};
  final Map<String, TextEditingController> otpControllers = {};

  TextEditingController getAmountController(String shipmentId) {
    return amountControllers.putIfAbsent(
        shipmentId, () => TextEditingController());
  }

  TextEditingController getChequeController(String shipmentId) {
    return chequeControllers.putIfAbsent(
        shipmentId, () => TextEditingController());
  }

  TextEditingController getAccountController(String shipmentId) {
    return accountControllers.putIfAbsent(
        shipmentId, () => TextEditingController());
  }

  TextEditingController getOnlineController(String shipmentId) {
    return onlineControllers.putIfAbsent(
        shipmentId, () => TextEditingController());
  }

  TextEditingController getOtpController(String shipmentId) {
    return otpControllers.putIfAbsent(
        shipmentId, () => TextEditingController());
  }

  TextEditingController amountController = TextEditingController();
  var isLoadingPayment = false.obs;

  void initializeUserId() async {
    final userData = await LocalStorage().getUserLocalData();
    currentUserId.value = userData?.messangerdetail?.id.toString() ?? '-1';
  }

  Future<void> getDeliveryData() async {
    isDeliveryLoading.value = Status.loading;
    try {
      final success = await pickupRepo.getAllDeliveryRepo('0');
      if (success != null) {
        deliveryList.value = success;
        filteredDeliveryList.value = success;
        isDeliveryLoading.value = Status.success;

        // Initialize amount controllers per shipment with totalCharges
        for (var delivery in success) {
          final controller =
              getAmountController(delivery.shipmentId.toString());
          controller.text = delivery.totalCharges.toString();
        }
      } else {
        Utils().logInfo('No delivery Record Found!');
        isDeliveryLoading.value = Status.error;
      }
    } catch (e) {
      Utils().logError(e.toString());
      deliveryList.value = [];
      filteredDeliveryList.value = [];
      isDeliveryLoading.value = Status.error;
    }
  }

  Future<void> getOtp(final shipmentID) async {
    // prevent spamming while loading or within cooldown

    if (isOtpLoading.value == Status.loading || !canResend.value) return;

    isOtpLoading.value = Status.loading;
    try {
      final success = await pickupRepo.getOtpRepo(shipmentID);

      if (success == true) {
        // start cooldown timer
        _startResendCooldown();
        isOtpSent.value = true;
        otpStatusMessage.value = 'OTP sent successfully';
        isOtpLoading.value = Status.success;
      } else {
        isOtpSent.value = false;
        otpStatusMessage.value = '';
        Get.snackbar(
          'Error',
          'Failed to send OTP',
          backgroundColor: themes.redColor,
          colorText: themes.whiteColor,
        );
        isOtpLoading.value = Status.error;
      }
    } catch (e) {
      isOtpSent.value = false;
      otpStatusMessage.value = '';
      Get.snackbar(
        'Error',
        'Failed to send OTP: $e',
        backgroundColor: themes.redColor,
        colorText: themes.whiteColor,
      );
      isOtpLoading.value = Status.error;
    } finally {
      if (isOtpLoading.value == Status.loading) {
        isOtpLoading.value = Status.initial;
      }
    }
  }

  void resetOtpState() {
    _resendTimer?.cancel();
    secondsLeft.value = 0;
    canResend.value = true;
    isOtpLoading.value = Status.initial;
    isUploadDelivery.value = Status.initial;
    isOtpSent.value = false;
    otpStatusMessage.value = '';
    submitStatusMessage.value = '';
    isSubmitStatusError.value = false;
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    secondsLeft.value = _cooldownSecs;
    canResend.value = false;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = secondsLeft.value - 1;
      if (next <= 0) {
        t.cancel();
        secondsLeft.value = 0;
        canResend.value = true;
      } else {
        secondsLeft.value = next;
      }
    });
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    super.onClose();
  }

  Future<bool> uploadDelivery(
    shipmentID,
    shipmentStatus,
    id,
    date,
    amtPaid,
    cashAmount,
    paymentMode,
    subPaymentMode,
    deliveryOtp, {
    String? chequeNumber,
    String? receiverName,
  }) async {
    isUploadDelivery.value = Status.loading;
    submitStatusMessage.value = '';
    isSubmitStatusError.value = false;
    try {
      final success = await deliveryRepo.uploadDeliveryRepo(
        shipmentID,
        shipmentStatus,
        id,
        date,
        amtPaid,
        cashAmount,
        normalizePaymentModeValue(paymentMode),
        subPaymentMode,
        deliveryOtp,
        chequeNumber: chequeNumber,
        receiverName: receiverName,
      );

      if (success == true) {
        final successMessage =
            deliveryRepo.apiMessage?.trim().isNotEmpty == true
                ? deliveryRepo.apiMessage!.trim()
                : 'Delivery uploaded successfully';
        submitStatusMessage.value = successMessage;
        isSubmitStatusError.value = false;
        Get.snackbar(
          'Success',
          successMessage,
          backgroundColor: themes.darkCyanBlue,
          colorText: themes.whiteColor,
        );
        isUploadDelivery.value = Status.success;
        getDeliveryData();
        final historyController = Get.find<HistoryController>();
        historyController.getDeliveryHistory();
        otpController.clear();
        getOtpController(shipmentID.toString()).clear();
        getChequeController(shipmentID.toString()).clear();
        getSelectedSubPaymentMode(shipmentID.toString()).value = null;
        isOtpSent.value = false;
        otpStatusMessage.value = '';
        return true;
      } else {
        final message = _buildDeliveryFailureMessage(deliveryRepo.apiMessage);
        submitStatusMessage.value = message;
        isSubmitStatusError.value = true;
        Get.snackbar(
          'Failed',
          message,
          backgroundColor: themes.redColor,
          colorText: themes.whiteColor,
        );
        isUploadDelivery.value = Status.error;
        return false;
      }
    } catch (e) {
      final message = _buildDeliveryFailureMessage(e.toString());
      submitStatusMessage.value = message;
      isSubmitStatusError.value = true;
      Get.snackbar(
        'Failed',
        message,
        backgroundColor: themes.redColor,
        colorText: themes.whiteColor,
      );
      isUploadDelivery.value = Status.error;
      return false;
    }
  }

  void filterByPincode(String query) {
    if (query.isEmpty) {
      filteredDeliveryList.value = deliveryList;
    } else {
      filteredDeliveryList.value = deliveryList
          .where((pickup) => (pickup.pincode ?? '').contains(query.trim()))
          .toList();
    }
  }

  Future<void> fetchPaymentModes() async {
    isLoadingPayment.value = true;
    try {
      final response = await dio.get(apiClient.baseUrl + getPaymentModePoint);

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = PaymentModesResponse.fromJson(response.data);

        subPaymentModes.value = _withContractMode(data.data.subPaymentModes);
      } else {
        Get.snackbar('Error', 'Failed to fetch payment modes');
      }
    } catch (e) {
      Get.snackbar('Error', 'Dio Error: $e');
    } finally {
      isLoadingPayment.value = false;
    }
  }

  @override
  void onInit() {
    // getDeliveryData();
    initializeUserId();
    // historyController.getDeliveryHistory('0');
    super.onInit();
  }

  String normalizePaymentModeValue(dynamic paymentMode) {
    final rawValue = paymentMode?.toString().trim() ?? '';
    final normalized =
        rawValue.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalized == 'topay') {
      return 'topay';
    }
    return rawValue;
  }

  bool isToPayPaymentMode(dynamic paymentMode) =>
      normalizePaymentModeValue(paymentMode) == 'topay';

  List<PaymentMode> _withContractMode(List<PaymentMode> modes) {
    final hasContract = modes.any(
      (mode) =>
          mode.id.toLowerCase() == 'contract' ||
          mode.name.toLowerCase() == 'contract',
    );
    if (hasContract) {
      return modes;
    }
    return [
      ...modes,
      PaymentMode(id: 'contract', name: 'Contract'),
    ];
  }

  String _buildDeliveryFailureMessage(String? rawMessage) {
    final message = (rawMessage ?? '').trim();
    if (message.isEmpty) {
      return 'Delivery uploaded failed';
    }

    final normalized = message.toLowerCase();
    final isOtpFailure =
        (normalized.contains('invalid') || normalized.contains('invailid')) &&
            normalized.contains('delivery otp');
    if (isOtpFailure || normalized.contains('expired delivery otp')) {
      return 'Your OTP is wrong or expired.';
    }

    return message;
  }
}
