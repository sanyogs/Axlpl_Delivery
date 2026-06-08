// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:axlpl_delivery/utils/utils.dart';

Widget dropdownText(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(
      text,
      style: themes.fontSize16_400.copyWith(fontSize: 14.sp),
    ),
  );
}

// Widget CommonDropdown(
//     {required String hint,
//     required Rxn<String> selectedValue,
//     required Function(String?) onChanged,
//     VoidCallback? onTap,
//     required List<String> items}) {
//   return

// }
class CommonDropdown<T> extends StatelessWidget {
  final String hint;
  final String? selectedValue;
  final Function(String?) onChanged;
  final VoidCallback? onTap;
  final bool isLoading;
  final List<T> items;
  final String Function(T) itemLabel;
  final String Function(T) itemValue;
  final isSearchable;
  final bool compact;
  CommonDropdown({
    Key? key,
    required this.hint,
    required this.selectedValue,
    required this.onChanged,
    required this.isLoading,
    required this.items,
    required this.itemLabel,
    required this.itemValue,
    this.onTap,
    this.isSearchable,
    this.compact = false,
  }) : super(key: key);

  String? _labelForSelectedValue() {
    final id = selectedValue?.trim();
    if (id == null || id.isEmpty || items.isEmpty) return null;
    for (final item in items) {
      if (itemValue(item) == id) return itemLabel(item);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: compact ? themes.fontSize14_400 : null,
          isDense: compact,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 10 : 14,
          ),
        ),
        child: Text(
          'Loading…',
          style: themes.fontSize14_400.copyWith(
            color: themes.grayColor,
            fontSize: compact ? 13 : null,
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: compact ? themes.fontSize14_400 : null,
          isDense: compact,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 10 : 14,
          ),
        ),
        child: Text(
          'No options',
          style: themes.fontSize14_400.copyWith(
            color: themes.grayColor,
            fontSize: compact ? 13 : null,
          ),
        ),
      );
    }
    return DropdownSearch<String>(
      items: items.map(itemLabel).toList(),
      selectedItem: _labelForSelectedValue(),
      dropdownDecoratorProps: DropDownDecoratorProps(
        baseStyle:
            compact ? themes.fontSize14_400.copyWith(fontSize: 13) : null,
        dropdownSearchDecoration: InputDecoration(
          labelText: hint,
          labelStyle: compact ? themes.fontSize14_400 : null,
          isDense: compact,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 10 : 14,
          ),
        ),
      ),
      popupProps: PopupProps.menu(
        fit: FlexFit.loose,
        showSearchBox: isSearchable ?? false,
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Search...',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      onChanged: (label) {
        if (label == null || label.trim().isEmpty) {
          onChanged(null);
          return;
        }
        for (final item in items) {
          if (itemLabel(item) == label) {
            onChanged(itemValue(item));
            return;
          }
        }
      },
    );
  }
}
