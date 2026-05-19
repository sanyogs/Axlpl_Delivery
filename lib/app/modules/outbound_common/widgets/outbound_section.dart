import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card section matching messenger form groupings.
class OutboundSection extends StatelessWidget {
  const OutboundSection({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Text(title, style: themes.fontSize18_600),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(
                subtitle!,
                style: themes.fontSize14_400.copyWith(color: themes.grayColor),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}
