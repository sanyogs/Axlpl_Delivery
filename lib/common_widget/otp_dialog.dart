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
  String title = 'OTP sent to registered mobile number',
  String confirmText = 'Submit',
}) {
  Future.microtask(onOtpCallback);

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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
            Text(
              'Enter OTP',
              style: themes.fontSize14_500.copyWith(color: themes.grayColor),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Pinput(
                length: 4,
                controller: otpController,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: themes.darkCyanBlue),
                  ),
                ),
                hapticFeedbackType: HapticFeedbackType.lightImpact,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final loading = otpLoading.value == Status.loading;
              final enabled = canResend.value;
              final label =
                  enabled ? 'Resend OTP' : 'Resend in ${secondsLeft.value}s';

              return Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: !enabled || loading ? null : onOtpCallback,
                  style: TextButton.styleFrom(
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
                            color: enabled
                                ? themes.darkCyanBlue
                                : themes.grayColor,
                            fontWeight: FontWeight.w600,
                          ),
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
                final isSubmitting = submitLoading.value == Status.loading;
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
                            Navigator.of(
                              Get.overlayContext!,
                              rootNavigator: true,
                            ).pop(true);
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
            ),
          ],
        ),
      ],
    ),
    barrierDismissible: false,
  );
}
