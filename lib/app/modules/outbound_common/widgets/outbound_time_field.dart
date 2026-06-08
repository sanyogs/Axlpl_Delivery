import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Tap-to-pick time — stores `HH:mm` in the controller.
class OutboundTimeField extends StatelessWidget {
  const OutboundTimeField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final parts = controller.text.trim().split(':');
        var hour = 0;
        var minute = 0;
        if (parts.length >= 2) {
          hour = int.tryParse(parts[0]) ?? 0;
          minute = int.tryParse(parts[1]) ?? 0;
        }
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59)),
        );
        if (picked != null) {
          controller.text =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        }
      },
      child: AbsorbPointer(
        child: Container(
          decoration: BoxDecoration(
            color: themes.lightGrayColor.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(color: themes.grayColor.withValues(alpha: 0.25)),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: true,
            style: themes.fontSize14_400.copyWith(fontSize: 12.5.sp),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              hintText: hintText,
              hintStyle: themes.fontSize14_400.copyWith(
                color: themes.grayColor,
                fontSize: 12.5.sp,
              ),
              border: InputBorder.none,
              suffixIcon: Icon(
                Icons.access_time,
                size: 18.sp,
                color: themes.grayColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
