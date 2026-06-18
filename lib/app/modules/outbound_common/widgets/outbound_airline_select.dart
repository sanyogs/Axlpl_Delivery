import 'package:axlpl_delivery/app/data/models/outbound/outbound_airline_option.dart';
import 'package:axlpl_delivery/common_widget/common_dropdown.dart';
import 'package:flutter/material.dart';

/// Airline picker backed by `getairlines`.
class OutboundAirlineSelect extends StatelessWidget {
  const OutboundAirlineSelect({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onChanged,
    this.isLoading = false,
    this.dropdownHint = 'Select airline',
    this.showLabel = false,
    this.compact = true,
  });

  final List<OutboundAirlineOption> items;
  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool isLoading;
  final String dropdownHint;
  final bool showLabel;
  final bool compact;

  List<OutboundAirlineOption> get _itemsWithSelectedFallback {
    final selected = selectedId?.trim();
    if (selected == null || selected.isEmpty) return items;
    if (items.any((a) => a.id == selected)) return items;
    return [
      ...items,
      OutboundAirlineOption(id: selected, name: selected),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLabel) dropdownText(dropdownHint),
        CommonDropdown<OutboundAirlineOption>(
          hint: dropdownHint,
          compact: compact,
          isSearchable: true,
          isLoading: isLoading,
          selectedValue: selectedId,
          items: _itemsWithSelectedFallback,
          itemLabel: (a) => a.label,
          itemValue: (a) => a.id,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
