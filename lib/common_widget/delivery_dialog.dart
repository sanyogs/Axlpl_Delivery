import 'package:axlpl_delivery/app/data/models/payment_mode_model.dart';
import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/app/modules/delivery/controllers/delivery_controller.dart';
import 'package:axlpl_delivery/common_widget/common_dropdown.dart';
import 'package:axlpl_delivery/common_widget/common_textfiled.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class DeliveryDialog extends StatelessWidget {
  final String shipmentID;
  final String date;
  final TextEditingController amountController;
  final TextEditingController chequeNumberController;
  // final TextEditingController accountNumberController;
  // final TextEditingController onlineNumberController;
  final TextEditingController otpController;
  final String dropdownHintTxt;
  final String btnTxt;
  final Future<bool> Function()? onConfirmCallback;
  final Future<void> Function()? onSendOtpCallback;

  DeliveryDialog({
    required this.shipmentID,
    required this.date,
    required this.amountController,
    required this.chequeNumberController,
    required this.otpController,
    required this.dropdownHintTxt,
    required this.btnTxt,
    this.onConfirmCallback,
    this.onSendOtpCallback,
    // required this.accountNumberController,
    // required this.onlineNumberController,
  });

  final DeliveryController deliveryController =
      Get.isRegistered<DeliveryController>()
          ? Get.find<DeliveryController>()
          : Get.put(DeliveryController());

  final defaultPinTheme = PinTheme(
    width: 56,
    height: 60,
    textStyle: const TextStyle(
      fontSize: 22,
      color: Color.fromRGBO(30, 60, 87, 1),
    ),
    decoration: BoxDecoration(
      color: themes.blueGray,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.transparent),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final selectedSubPaymentMode =
        deliveryController.getSelectedSubPaymentMode(shipmentID);
    return AlertDialog(
      backgroundColor: themes.whiteColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Collect Payment',
        style: themes.fontSize18_600.copyWith(color: themes.darkCyanBlue),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400.w,
          child: Column(
            spacing: 10.h,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              dropdownText('Payment Mode'),
              Obx(() {
                if (deliveryController.isLoadingPayment.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<PaymentMode>(
                      hint: Text(dropdownHintTxt),
                      value: selectedSubPaymentMode.value,
                      items: deliveryController.subPaymentModes
                          .map((mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        deliveryController.setSelectedSubPaymentMode(
                          shipmentID,
                          val,
                        );

                        if (val == null ||
                            val.id == 'cash' ||
                            deliveryController.isContractSubPaymentMode(val)) {
                          chequeNumberController.clear();
                        }
                      },
                    ),
                  ),
                );
              }),
              Obx(() {
                final selectedMode = selectedSubPaymentMode.value;
                final isContractMode =
                    deliveryController.isContractSubPaymentMode(selectedMode);

                if (isContractMode) {
                  return const SizedBox.shrink();
                }

                return CommonTextfiled(
                  controller: amountController,
                  obscureText: false,
                  hintTxt: 'Enter Amount',
                  lableText: 'Enter Amount',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = int.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }
                    if (amount < 1) {
                      return 'Amount must be at least 1';
                    }
                    return null;
                  },
                );
              }),
              Obx(() {
                final selectedMode = selectedSubPaymentMode.value;
                final isContractMode =
                    deliveryController.isContractSubPaymentMode(selectedMode);

                if (selectedMode == null ||
                    selectedMode.id == 'cash' ||
                    isContractMode) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dropdownText(
                      selectedMode.id == 'cheque'
                          ? 'Cheque Number'
                          : 'Transaction ID',
                    ),
                    CommonTextfiled(
                      controller: chequeNumberController,
                      hintTxt: selectedMode.id == 'cheque'
                          ? 'Enter Cheque Number'
                          : 'Enter Transaction ID',
                      keyboardType: TextInputType.text,
                    ),
                  ],
                );
              }),
              Text(
                'Enter OTP',
                style: themes.fontSize14_500.copyWith(
                  color: themes.blackColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Enter the 4-digit OTP shared with the receiver.',
                style: themes.fontSize14_500.copyWith(color: themes.grayColor),
              ),
              SizedBox(
                width: double.infinity,
                child: Pinput(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                  length: 4,
                  controller: otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: themes.darkCyanBlue),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyWith(
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Obx(() {
                  final loading =
                      deliveryController.isOtpLoading.value == Status.loading;
                  final canResend = deliveryController.canResend.value;
                  final secs = deliveryController.secondsLeft.value;
                  final label = canResend ? 'Resend OTP' : 'Resend in ${secs}s';

                  return TextButton(
                    onPressed: (!canResend || loading)
                        ? null
                        : () async {
                            final sendOtp = onSendOtpCallback ??
                                () => deliveryController.getOtp(shipmentID);
                            await sendOtp();
                          },
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: themes.darkCyanBlue,
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            label,
                            style: themes.fontSize14_500.copyWith(
                              color: canResend
                                  ? themes.darkCyanBlue
                                  : themes.grayColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                }),
              ),
              Obx(() {
                final message =
                    deliveryController.submitStatusMessage.value.trim();
                if (message.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Text(
                  message,
                  style: themes.fontSize14_500.copyWith(
                    color: deliveryController.isSubmitStatusError.value
                        ? themes.redColor
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: themes.darkCyanBlue,
                  side: BorderSide(color: themes.darkCyanBlue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.of(
                  Get.overlayContext!,
                  rootNavigator: true,
                ).pop(false),
                child: Text(
                  'Cancel',
                  style: themes.fontSize14_500.copyWith(
                    color: themes.darkCyanBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Obx(() {
                final isSubmitting =
                    deliveryController.isUploadDelivery.value == Status.loading;
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themes.darkCyanBlue,
                    foregroundColor: themes.whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: isSubmitting ? 8 : 2,
                    shadowColor: themes.darkCyanBlue.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          FocusManager.instance.primaryFocus?.unfocus();
                          if (otpController.text.length != 4) {
                            Get.snackbar(
                              'Invalid OTP',
                              'Please enter all 4 digits.',
                              colorText: themes.whiteColor,
                              backgroundColor: themes.redColor,
                            );
                            return;
                          }

                          if (onConfirmCallback != null) {
                            final isSuccess = await onConfirmCallback!();
                            if (!isSuccess) {
                              return;
                            }
                            if (Get.overlayContext != null) {
                              Navigator.of(
                                Get.overlayContext!,
                                rootNavigator: true,
                              ).pop(true);
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          btnTxt,
                          style: themes.fontSize14_500.copyWith(
                            color: themes.whiteColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
