import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

Future<void> outboundCopyToClipboard(
  String? value, {
  String snackbarTitle = 'Outbound',
}) async {
  final text = value?.trim();
  if (text == null || text.isEmpty || text == '—') return;
  await Clipboard.setData(ClipboardData(text: text));
  Get.snackbar(snackbarTitle, 'Copied to clipboard.');
}

/// Table cell with optional copy icon for IDs, codes, and references.
class OutboundCopyableTableCell extends StatelessWidget {
  const OutboundCopyableTableCell({
    super.key,
    this.value,
    this.displayText,
    this.emphasized = false,
    this.textStyle,
    this.snackbarTitle = 'Outbound',
    this.dense = false,
    this.maxLines,
  });

  final String? value;
  final String? displayText;
  final bool emphasized;
  final TextStyle? textStyle;
  final String snackbarTitle;
  final bool dense;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return Text('—', style: themes.fontSize14_400);
    }
    final shown = displayText?.trim().isNotEmpty == true
        ? displayText!.trim()
        : raw;
    final style = textStyle ??
        (emphasized
            ? themes.fontSize14_500.copyWith(color: themes.darkCyanBlue)
            : themes.fontSize14_400);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            shown,
            style: style,
            softWrap: true,
            maxLines: maxLines,
            overflow:
                maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
          ),
        ),
        IconButton(
          tooltip: OutboundLabels.btnCopy,
          onPressed: () => outboundCopyToClipboard(raw, snackbarTitle: snackbarTitle),
          icon: Icon(
            Icons.copy_outlined,
            size: dense ? 14.sp : 16.sp,
            color: themes.darkCyanBlue,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints(
            minWidth: dense ? 24.w : 28.w,
            minHeight: dense ? 24.w : 28.w,
          ),
        ),
      ],
    );
  }
}

/// Inline label/value row with copy icon (summary cells, badges).
class OutboundCopyableInline extends StatelessWidget {
  const OutboundCopyableInline({
    super.key,
    required this.text,
    this.value,
    this.style,
    this.snackbarTitle = 'Outbound',
    this.compact = false,
  });

  final String text;
  final String? value;
  final TextStyle? style;
  final String snackbarTitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final raw = (value ?? text).trim();
    if (raw.isEmpty || raw == '—') {
      return Text(text, style: style);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            style: style,
            softWrap: true,
          ),
        ),
        IconButton(
          tooltip: OutboundLabels.btnCopy,
          onPressed: () => outboundCopyToClipboard(raw, snackbarTitle: snackbarTitle),
          icon: Icon(
            Icons.copy_outlined,
            size: compact ? 14.sp : 16.sp,
            color: themes.darkCyanBlue,
          ),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints(
            minWidth: compact ? 24.w : 28.w,
            minHeight: compact ? 24.w : 28.w,
          ),
        ),
      ],
    );
  }
}
