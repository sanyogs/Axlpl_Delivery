import 'package:axlpl_delivery/app/data/models/outbound/outbound_branch_option.dart';
import 'package:axlpl_delivery/common_widget/common_dropdown.dart';
import 'package:flutter/material.dart';

/// Depot / branch picker — select only (no free-text branch id).
class OutboundBranchSelect extends StatelessWidget {
  const OutboundBranchSelect({
    super.key,
    required this.label,
    required this.items,
    required this.selectedId,
    required this.onChanged,
    this.isLoading = false,
    this.isSearchable = true,
  });

  final String label;
  final List<OutboundBranchOption> items;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool isLoading;
  final bool isSearchable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        dropdownText(label),
        CommonDropdown<OutboundBranchOption>(
          hint: label,
          isSearchable: isSearchable,
          isLoading: isLoading,
          selectedValue: selectedId,
          items: items,
          itemLabel: (b) {
            final code = b.code?.trim();
            if (code != null && code.isNotEmpty) {
              return '${b.label} ($code)';
            }
            return b.label;
          },
          itemValue: (b) => b.id,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
