import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// Modal shell for outbound admin forms — [OutboundAdminSection] only (no nested cards).
class OutboundAdminDialog extends StatelessWidget {
  const OutboundAdminDialog({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  static Future<T?> show<T>({
    required String title,
    required List<Widget> children,
    Widget? trailing,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<T>(
      wrap(
        OutboundAdminSection(
          title: title,
          trailing: trailing,
          children: children,
        ),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Transparent dialog shell around one admin section card.
  static Widget wrap(Widget child) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Material(
        color: Colors.transparent,
        child: SingleChildScrollView(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return wrap(
      OutboundAdminSection(
        title: title,
        trailing: trailing,
        children: children,
      ),
    );
  }
}
