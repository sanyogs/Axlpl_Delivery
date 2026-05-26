import 'package:axlpl_delivery/common_widget/common_button.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Outbound-only button system — matches [CommonButton] (cyan primary) and
/// dialog/pickup secondary style (outlined cyan, no Material purple tint).
abstract final class OutboundButtons {
  OutboundButtons._();

  /// Shared touch height for primary + secondary (aligned in rows).
  static double get height => 48.h;

  /// Horizontal gap between side-by-side actions.
  static double get rowGap => 10.w;

  static ButtonStyle secondaryStyle({bool enabled = true}) {
    return OutlinedButton.styleFrom(
      foregroundColor: themes.darkCyanBlue,
      backgroundColor: themes.whiteColor,
      disabledForegroundColor: themes.grayColor,
      disabledBackgroundColor: themes.lightGrayColor.withValues(alpha: 0.35),
      side: BorderSide(
        color: enabled ? themes.darkCyanBlue : themes.grayColor,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      minimumSize: Size(double.infinity, height),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: themes.fontReboto16_600.copyWith(
        fontSize: 13.sp,
        color: enabled ? themes.darkCyanBlue : themes.grayColor,
      ),
      surfaceTintColor: Colors.transparent,
      overlayColor: themes.darkCyanBlue.withValues(alpha: 0.08),
    );
  }
}

/// Full-width primary CTA — same as messenger [CommonButton].
class OutboundPrimaryButton extends StatelessWidget {
  const OutboundPrimaryButton({
    super.key,
    required this.title,
    this.onPressed,
    this.isLoading,
  });

  final String title;
  final VoidCallback? onPressed;
  final bool? isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: OutboundButtons.height,
      child: CommonButton(
        title: title,
        onPressed: onPressed,
        isLoading: isLoading,
      ),
    );
  }
}

/// Primary action sized for half-width rows — scales long titles down.
class OutboundPrimaryButtonCompact extends StatelessWidget {
  const OutboundPrimaryButtonCompact({
    super.key,
    required this.title,
    this.onPressed,
    this.isLoading,
  });

  final String title;
  final VoidCallback? onPressed;
  final bool? isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final labelColor = enabled ? themes.whiteColor : themes.grayColor;
    final spinnerColor = enabled ? themes.whiteColor : themes.darkCyanBlue;
    return SizedBox(
      width: double.infinity,
      height: OutboundButtons.height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return themes.lightGrayColor.withValues(alpha: 0.55);
            }
            return themes.darkCyanBlue;
          }),
          foregroundColor: WidgetStatePropertyAll(labelColor),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: themes.grayColor.withValues(alpha: 0.45));
            }
            return BorderSide.none;
          }),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
          ),
          minimumSize: WidgetStatePropertyAll(Size(double.infinity, OutboundButtons.height)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: isLoading == true
            ? SizedBox(
                height: 18.h,
                width: 18.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: spinnerColor,
                ),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: themes.fontReboto16_600.copyWith(
                    fontSize: 13.sp,
                    color: labelColor,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Full-width secondary action — cyan outline on white (not theme purple).
class OutboundSecondaryButton extends StatelessWidget {
  const OutboundSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      height: OutboundButtons.height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutboundButtons.secondaryStyle(enabled: enabled),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Two equal-width actions in one row (secondary pair or mixed).
class OutboundButtonRow extends StatelessWidget {
  const OutboundButtonRow({
    super.key,
    required this.start,
    required this.end,
  });

  final Widget start;
  final Widget end;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: start),
        SizedBox(width: OutboundButtons.rowGap),
        Expanded(child: end),
      ],
    );
  }
}

/// Secondary left, primary right — common hub-scan pattern.
class OutboundSecondaryPrimaryRow extends StatelessWidget {
  const OutboundSecondaryPrimaryRow({
    super.key,
    required this.secondaryLabel,
    required this.primaryTitle,
    this.onSecondary,
    this.onPrimary,
    this.primaryLoading,
  });

  final String secondaryLabel;
  final String primaryTitle;
  final VoidCallback? onSecondary;
  final VoidCallback? onPrimary;
  final bool? primaryLoading;

  @override
  Widget build(BuildContext context) {
    return OutboundButtonRow(
      start: OutboundSecondaryButton(
        label: secondaryLabel,
        onPressed: onSecondary,
      ),
      end: OutboundPrimaryButtonCompact(
        title: primaryTitle,
        onPressed: onPrimary,
        isLoading: primaryLoading,
      ),
    );
  }
}
