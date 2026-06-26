import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeIconContainer extends StatelessWidget {
  String? title;
  /// Asset path (`String`) or Material icon (`IconData`).
  final Object? Img;
  final VoidCallback? OnTap;
  HomeIconContainer({
    super.key,
    this.title,
    this.Img,
    this.OnTap,
  });

  Widget _tileIcon() {
    final img = Img;
    if (img is IconData) {
      return Icon(
        img,
        size: 30.w,
        color: themes.darkCyanBlue,
      );
    }
    if (img is String) {
      return Image.asset(
        img,
        width: 30.w,
        height: 30.w,
        fit: BoxFit.contain,
      );
    }
    return SizedBox(width: 30.w, height: 30.w);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: OnTap,
      child: Container(
        decoration: BoxDecoration(
            color: themes.whiteColor, borderRadius: BorderRadius.circular(5.r)),
        child: Padding(
          // Use .w for vertical padding — grid tile height is width-derived;
          // .h padding on tall phones overflows and clips PNG icons at the bottom.
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8.w,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? 'N/A',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: themes.fontSize14_500,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _tileIcon(),
                  CircleAvatar(
                    backgroundColor: themes.lightCream,
                    radius: 15.r,
                    child: Icon(Icons.arrow_forward, size: 16.sp),
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
