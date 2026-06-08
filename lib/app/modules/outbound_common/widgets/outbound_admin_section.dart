import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Blue header + white body card (admin outbound screens).
class OutboundAdminSection extends StatelessWidget {
  const OutboundAdminSection({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: themes.darkCyanBlue,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: themes.fontSize18_600.copyWith(
                      color: themes.whiteColor,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// Label left, field right — matches admin form rows.
class OutboundLabeledFieldRow extends StatelessWidget {
  const OutboundLabeledFieldRow({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final labelWidget = RichText(
      text: TextSpan(
        style: themes.fontSize14_400.copyWith(
          color: themes.blackColor,
          fontSize: 11.5.sp,
          height: 1.12,
        ),
        children: [
          TextSpan(text: '$label :'),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red.shade700),
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              labelWidget,
              SizedBox(height: 4.h),
              child,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 110.w,
              child: labelWidget,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

/// Read-only grey input populated from API (admin auto-fill fields).
class OutboundReadOnlyInput extends StatelessWidget {
  const OutboundReadOnlyInput({
    super.key,
    required this.controller,
    this.hintText = '',
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: themes.lightGrayColor.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: themes.grayColor.withValues(alpha: 0.25)),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        enableInteractiveSelection: true,
        style: themes.fontSize14_400.copyWith(fontSize: 12.5.sp),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          hintText: hintText,
          hintStyle: themes.fontSize14_400.copyWith(
            color: themes.grayColor,
            fontSize: 12.5.sp,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
