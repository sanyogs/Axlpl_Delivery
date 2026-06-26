import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Renders an outbound PNG at its natural aspect ratio (wide/tall — not forced square).
class OutboundMenuIcon extends StatelessWidget {
  const OutboundMenuIcon({
    super.key,
    required this.assetPath,
    this.maxWidth = 36,
    this.maxHeight = 26,
  });

  final String assetPath;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth.w,
        maxHeight: maxHeight.w,
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

/// Outbound submenu tile — PNG icons keep their natural aspect ratio (not forced square).
class OutboundMenuTile extends StatelessWidget {
  const OutboundMenuTile({
    super.key,
    required this.title,
    required this.assetPath,
    required this.onTap,
    this.maxIconWidth = 36,
    this.maxIconHeight = 26,
  });

  final String title;
  final String assetPath;
  final VoidCallback onTap;
  final double maxIconWidth;
  final double maxIconHeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: themes.whiteColor,
          borderRadius: BorderRadius.circular(5.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 15.h),
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                overflow: TextOverflow.fade,
                style: themes.fontSize14_500,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  OutboundMenuIcon(
                    assetPath: assetPath,
                    maxWidth: maxIconWidth,
                    maxHeight: maxIconHeight,
                  ),
                  CircleAvatar(
                    backgroundColor: themes.lightCream,
                    radius: 15,
                    child: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
