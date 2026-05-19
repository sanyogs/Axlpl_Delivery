import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OutboundResponsePanel extends StatelessWidget {
  const OutboundResponsePanel({
    super.key,
    required this.text,
    this.title = 'Last response',
  });

  final String text;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      color: themes.lightGrayColor.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: themes.fontSize14_500),
            SizedBox(height: 8.h),
            SelectableText(text, style: themes.fontSize14_400),
          ],
        ),
      ),
    );
  }
}
