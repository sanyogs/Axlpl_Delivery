import 'package:axlpl_delivery/common_widget/common_datepicker.dart';
import 'package:axlpl_delivery/common_widget/container_textfiled.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';

/// Tap-to-pick date using the app holo date picker.
class OutboundDateField extends StatelessWidget {
  const OutboundDateField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await holoDatePicker(
          context,
          hintText: hintText,
        );
        if (picked != null) {
          controller.text =
              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
        }
      },
      child: AbsorbPointer(
        child: ContainerTextfiled(
          controller: controller,
          hintText: hintText,
          prefixIcon: Icon(
            Icons.calendar_today_outlined,
            color: themes.grayColor,
          ),
        ),
      ),
    );
  }
}
