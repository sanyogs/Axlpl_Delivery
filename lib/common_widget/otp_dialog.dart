import 'package:axlpl_delivery/app/data/networking/data_state.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

Future<bool?> showOtpDialog({
  required Future<bool> Function() onConfirmCallback,
  required Future<void> Function() onOtpCallback,
  required TextEditingController otpController,
  required Rx<Status> otpLoading,
  required Rx<Status> submitLoading,
  required RxBool canResend,
  required RxInt secondsLeft,
  required RxBool isOtpSent,
  required RxString otpStatusMessage,
  RxString? submitStatusMessage,
  RxBool? isSubmitStatusError,
  String title = 'Enter OTP',
  String confirmText = 'Enter OTP',
}) {
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

  return Get.dialog<bool>(
    AlertDialog(
      backgroundColor: themes.whiteColor,
      title: Text(
        title,
        style: themes.fontSize18_600.copyWith(
          color: themes.blackColor,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 400.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: Pinput(
                length: 4,
                controller: otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: themes.darkCyanBlue),
                  ),
                ),
                hapticFeedbackType: HapticFeedbackType.lightImpact,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final loading = otpLoading.value == Status.loading;
              final enabled = canResend.value;
              final label =
                  enabled ? 'Send OTP' : 'Resend in ${secondsLeft.value}s';

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: enabled
                        ? themes.darkCyanBlue
                        : themes.grayColor.withValues(alpha: 0.45),
                    foregroundColor: themes.whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: !enabled || loading ? null : onOtpCallback,
                  child: loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          label,
                          style: themes.fontSize14_500.copyWith(
                            color: themes.whiteColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            }),
            Obx(() {
              if (!isOtpSent.value || otpStatusMessage.value.trim().isEmpty) {
                return const SizedBox(height: 0);
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  otpStatusMessage.value,
                  style: themes.fontSize14_500.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }),
            if (submitStatusMessage != null && isSubmitStatusError != null)
              Obx(() {
                final message = submitStatusMessage.value.trim();
                if (message.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    message,
                    style: themes.fontSize14_500.copyWith(
                      color: isSubmitStatusError.value
                          ? themes.redColor
                          : Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(Get.overlayContext!, rootNavigator: true).pop(false),
          child: Text(
            'Cancel',
            style: themes.fontSize14_500.copyWith(color: themes.darkCyanBlue),
          ),
        ),
        Obx(() {
          final isSubmitting = submitLoading.value == Status.loading;
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themes.darkCyanBlue,
              foregroundColor: themes.whiteColor,
              elevation: isSubmitting ? 8 : 2,
              shadowColor: themes.darkCyanBlue.withValues(alpha: 0.35),
            ),
            onPressed: isSubmitting
                ? null
                : () async {
                    FocusManager.instance.primaryFocus?.unfocus();
                    if (otpController.text.trim().length != 4) {
                      Get.snackbar(
                        'Invalid OTP',
                        'Please enter all 4 digits.',
                        colorText: themes.whiteColor,
                        backgroundColor: themes.redColor,
                      );
                      return;
                    }

                    final isSuccess = await onConfirmCallback();
                    if (!isSuccess) {
                      return;
                    }

                    if (Get.overlayContext != null) {
                      Navigator.of(Get.overlayContext!, rootNavigator: true)
                          .pop(true);
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
                    confirmText,
                    style: themes.fontSize14_500.copyWith(
                      color: themes.whiteColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          );
        }),
      ],
    ),
    barrierDismissible: false,
  );
}
