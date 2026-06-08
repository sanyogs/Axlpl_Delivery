import 'package:axlpl_delivery/common_widget/common_dropdown.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// String enum picker — no default selection; user must choose an option.
class OutboundSelectField extends StatelessWidget {
  const OutboundSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hint = 'Select',
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final String hint;

  String? get _effectiveValue {
    final v = value?.trim();
    if (v == null || v.isEmpty) return null;
    return options.contains(v) ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.trim().isNotEmpty) dropdownText(label),
        Container(
          decoration: BoxDecoration(
            color: themes.lightGrayColor,
            borderRadius: BorderRadius.circular(30.r),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _effectiveValue,
              hint: Text(
                hint,
                style: themes.fontSize14_400.copyWith(
                  color: themes.grayColor,
                  fontSize: 13,
                ),
              ),
              items: options
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: themes.fontSize14_400.copyWith(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: options.isEmpty
                  ? null
                  : (v) {
                      if (v != null) onChanged(v);
                    },
            ),
          ),
        ),
      ],
    );
  }
}
