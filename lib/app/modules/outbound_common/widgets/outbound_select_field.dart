import 'package:axlpl_delivery/common_widget/common_dropdown.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// String enum picker styled like the rest of the app.
class OutboundSelectField extends StatelessWidget {
  const OutboundSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        dropdownText(label),
        Container(
          decoration: BoxDecoration(
            color: themes.lightGrayColor,
            borderRadius: BorderRadius.circular(30.r),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: options.contains(value) ? value : options.first,
              items: options
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e, style: themes.fontSize16_400),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
