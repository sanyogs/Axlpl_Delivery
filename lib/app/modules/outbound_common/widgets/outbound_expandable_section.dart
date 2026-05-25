import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Collapsible outbound card — keeps long screens shorter until expanded.
class OutboundExpandableSection extends StatelessWidget {
  const OutboundExpandableSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: themes.whiteColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          childrenPadding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
          title: Text(title, style: themes.fontSize18_600),
          subtitle: subtitle != null && subtitle!.isNotEmpty
              ? Text(
                  subtitle!,
                  style: themes.fontSize14_400.copyWith(color: themes.grayColor),
                )
              : null,
          iconColor: themes.darkCyanBlue,
          collapsedIconColor: themes.darkCyanBlue,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable table area with a max height so the page does not grow endlessly.
class OutboundBoundedTableBox extends StatelessWidget {
  const OutboundBoundedTableBox({
    super.key,
    required this.child,
    this.maxHeight = 200,
  });

  final Widget child;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight.h),
      child: child,
    );
  }
}
