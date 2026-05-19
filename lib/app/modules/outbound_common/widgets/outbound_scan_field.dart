import 'dart:io';

import 'package:axlpl_delivery/common_widget/container_textfiled.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Search-style field with barcode scanner on the right (POD / shipnow pattern).
class OutboundScanField extends StatelessWidget {
  const OutboundScanField({
    super.key,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ContainerTextfiled(
            controller: controller,
            hintText: hintText,
            keyboardType: keyboardType,
            prefixIcon: prefixIcon ??
                Icon(
                  CupertinoIcons.barcode,
                  color: themes.grayColor,
                ),
            onSubmit: onSubmitted == null
                ? null
                : (v) {
                    onSubmitted!(v ?? '');
                    return null;
                  },
          ),
        ),
        IconButton(
          onPressed: () async {
            final scanned = await Utils().scanAndPlaySound(context);
            if (scanned != null && scanned != '-1') {
              controller.text = scanned;
            }
          },
          icon: Icon(
            CupertinoIcons.qrcode_viewfinder,
            size: Platform.isIOS ? 28.sp : 26,
            color: themes.darkCyanBlue,
          ),
        ),
      ],
    );
  }
}
