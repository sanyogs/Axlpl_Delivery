import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class CommonButton extends StatelessWidget {
  String title;
  final bool? isLoading;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  CommonButton({
    super.key,
    required this.title,
    this.onPressed,
    this.isLoading,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = themes.fontReboto16_600.copyWith(
      color: themes.whiteColor,
      fontSize: 16.sp,
    );
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: CupertinoButton(
        color: backgroundColor ?? themes.darkCyanBlue,
        focusColor: themes.whiteColor,
        borderRadius: BorderRadius.circular(20.r),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        onPressed: onPressed,
        child: isLoading == true
            ? SizedBox(
                height: 18.h,
                width: 18.h,
                child: SpinKitCubeGrid(
                  color: themes.whiteColor,
                  size: 18.h,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: labelStyle,
                ),
              ),
      ),
    );
  }
}
