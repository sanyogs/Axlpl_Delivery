import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Plain outbound input (no scanner) — matches messenger list screens.
class OutboundField extends StatelessWidget {
  const OutboundField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themes.lightGrayColor,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: themes.fontSize14_400.copyWith(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          hintText: hintText,
          hintStyle: themes.fontSize14_400.copyWith(
            color: themes.grayColor,
            fontSize: 13,
          ),
          border: InputBorder.none,
          prefixIcon: prefixIcon == null
              ? null
              : IconTheme(
                  data: IconThemeData(size: 20, color: themes.grayColor),
                  child: prefixIcon!,
                ),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 38, minHeight: 38),
        ),
      ),
    );
  }
}
