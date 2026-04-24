import 'dart:async';
import 'dart:io';

import 'package:axlpl_delivery/app/data/models/shipment_record_model.dart';
import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/app/data/networking/repostiory/pod_repo.dart';
// ignore: unused_import
import 'package:axlpl_delivery/app/data/networking/repostiory/profile_repo.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class PodController extends GetxController {
  //TODO: Implement PodController
  final _repo = PodRepo();
  TextEditingController shipmentIdController = TextEditingController();

  final shipmentRecordList = <ShipmentRecordList>[].obs;
  final shipmentLookupMessage = ''.obs;

  var imageFile = Rx<File?>(null);

  final paymentModes = [
    {'id': '1', 'name': 'Prepaid'},
    {'id': '2', 'name': 'To Pay'},
    {'id': '3', 'name': 'Paid Cash'},
    {'id': '4', 'name': 'To Pay Cash'},
    {'id': '5', 'name': 'Account (contract)'},
  ].obs;
  final paymentTypes = [
    {'id': '1', 'name': 'Account '},
    {'id': '2', 'name': 'Cash'},
    {'id': '3', 'name': 'Cheque'},
    {'id': '4', 'name': 'Online /add shipment'},
  ].obs;

  final isPod = Status.initial.obs;
  final isShipmentRecord = Status.initial.obs;

  final message = ''.obs;

  var selectedPaymentModeId = Rxn<String>();
  var selectedPaymentTypeId = Rxn<String>();

  Timer? _shipmentLookupDebounce;
  String _lastLookupShipmentId = '';

  @override
  void onInit() {
    super.onInit();
    shipmentIdController.addListener(_onShipmentIdTextChanged);
  }

  void _onShipmentIdTextChanged() {
    final shipmentId = shipmentIdController.text.trim();

    _shipmentLookupDebounce?.cancel();

    if (shipmentId.isEmpty) {
      _lastLookupShipmentId = '';
      shipmentLookupMessage.value = '';
      shipmentRecordList.clear();
      isShipmentRecord.value = Status.initial;
      return;
    }

    if (shipmentId != _lastLookupShipmentId) {
      shipmentLookupMessage.value = '';
      shipmentRecordList.clear();
      isShipmentRecord.value = Status.initial;
    }

    if (shipmentId.length < 6) {
      return;
    }

    _shipmentLookupDebounce = Timer(const Duration(milliseconds: 300), () {
      final latestValue = shipmentIdController.text.trim();
      if (latestValue.isEmpty ||
          latestValue.length < 6 ||
          latestValue == _lastLookupShipmentId) {
        return;
      }

      _lastLookupShipmentId = latestValue;
      getShipmentRecord(latestValue);
    });
  }

  Future<void> uploadPod({
    required String shipmentStatus,
    required String shipmentOtp,
    required File file,
  }) async {
    try {
      isPod.value = Status.loading;
      message.value = '';
      // Allow the UI to repaint loading state before starting the upload work.
      await Future<void>.delayed(Duration.zero);

      final result = await _repo.uploadPodRepo(
        shipmentIdController.text,
        shipmentStatus,
        shipmentOtp,
        file,
      );

      if (result) {
        isPod.value = Status.success;
        message.value = _repo.apiMessage ?? 'Upload successful';
        shipmentIdController.clear();

        Utils().showTopNotification(
          title: 'Success',
          message: message.value,
        );
        imageFile.value = null;
      } else {
        isPod.value = Status.error;
        message.value = _repo.apiMessage ?? 'Upload failed';
        Utils().showTopNotification(
          title: 'Failed',
          message: message.value,
          isError: true,
        );
      }
    } catch (e) {
      isPod.value = Status.error;
      message.value = 'Unexpected error: $e';
      Utils().showTopNotification(
        title: 'Failed',
        message: message.value,
        isError: true,
      );
    }
  }

  Future<void> getShipmentRecord(final shipmentID) async {
    final requestedShipmentId = shipmentID.toString().trim();
    if (requestedShipmentId.isEmpty) return;

    isShipmentRecord.value = Status.loading;
    shipmentLookupMessage.value = '';

    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await _repo.getShipmentRecordRepo(requestedShipmentId);

        if (shipmentIdController.text.trim() != requestedShipmentId) {
          return;
        }

        if (result.isNotEmpty) {
          shipmentRecordList.value = result;
          isShipmentRecord.value = Status.success;
          shipmentLookupMessage.value =
              _repo.apiMessage?.trim().isNotEmpty == true
                  ? _repo.apiMessage!.trim()
                  : 'Shipment fetched successfully';
          return;
        }

        shipmentRecordList.clear();
        isShipmentRecord.value = Status.error;
        shipmentLookupMessage.value =
            _repo.apiMessage?.trim().isNotEmpty == true
                ? _repo.apiMessage!.trim()
                : 'No shipment found for this ID';
        return;
      } catch (e) {
        Utils().logError(e.toString());

        if (shipmentIdController.text.trim() != requestedShipmentId) {
          return;
        }

        final msg = _repo.apiMessage?.trim();
        final msgLower = msg?.toLowerCase() ?? '';
        final isConnectivityError = msgLower.contains('internet') ||
            msgLower.contains('connect') ||
            msgLower.contains('timeout');

        if (attempt < maxAttempts && isConnectivityError) {
          final delayMs = 400 * attempt;
          await Future.delayed(Duration(milliseconds: delayMs));
          continue;
        }

        shipmentRecordList.clear();
        isShipmentRecord.value = Status.error;
        shipmentLookupMessage.value =
            msg?.isNotEmpty == true ? msg! : 'Unable to fetch shipment details';
        return;
      }
    }
  }

  @override
  void onClose() {
    _shipmentLookupDebounce?.cancel();
    shipmentIdController.dispose();
    super.onClose();
  }
}
