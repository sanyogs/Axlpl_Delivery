import 'package:axlpl_delivery/common_widget/container_textfiled.dart';
import 'package:flutter/material.dart';

/// Plain outbound input (no scanner) — matches messenger list screens.
class OutboundField extends StatelessWidget {
  const OutboundField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return ContainerTextfiled(
      controller: controller,
      hintText: hintText,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
    );
  }
}
