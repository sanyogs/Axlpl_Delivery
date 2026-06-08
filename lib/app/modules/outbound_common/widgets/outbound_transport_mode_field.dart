import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Airway / Surface radio — UI-only (not sent to manifest API).
class OutboundTransportModeField extends StatelessWidget {
  const OutboundTransportModeField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeTile(
          label: OutboundLabels.modeAirway,
          selected: value == OutboundLabels.modeAirway,
          onTap: () => onChanged(OutboundLabels.modeAirway),
        ),
        SizedBox(width: 16.w),
        _ModeTile(
          label: OutboundLabels.modeSurface,
          selected: value == OutboundLabels.modeSurface,
          onTap: () => onChanged(OutboundLabels.modeSurface),
        ),
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18.sp,
              color: selected ? themes.darkCyanBlue : themes.grayColor,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: themes.fontSize14_400.copyWith(
                fontSize: 12.sp,
                color: themes.blackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
