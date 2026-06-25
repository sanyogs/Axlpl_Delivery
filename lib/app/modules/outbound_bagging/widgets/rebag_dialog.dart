import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_labels.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_action_buttons.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_dialog.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_admin_section.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/widgets/outbound_scan_field.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

typedef RebagSubmitCallback = Future<void> Function({
  required String newBagCode,
  required String docketNo,
});

/// Admin rebag form — same layout as bagging / sector-pickup scan rows.
class RebagDialog extends StatefulWidget {
  const RebagDialog({
    super.key,
    required this.onSubmit,
    this.sourceBag,
  });

  final RebagSubmitCallback onSubmit;
  final OutboundBagRow? sourceBag;

  static Future<void> show({
    required RebagSubmitCallback onSubmit,
    OutboundBagRow? sourceBag,
  }) {
    return Get.dialog<void>(
      OutboundAdminDialog.wrap(
        RebagDialog(sourceBag: sourceBag, onSubmit: onSubmit),
      ),
      barrierDismissible: true,
    );
  }

  @override
  State<RebagDialog> createState() => _RebagDialogState();
}

class _RebagDialogState extends State<RebagDialog> {
  late final TextEditingController _sourceBagController;
  late final TextEditingController _newBagController;
  late final TextEditingController _docketController;
  late final FocusNode _newBagFocusNode;
  late final FocusNode _docketFocusNode;

  @override
  void initState() {
    super.initState();
    _sourceBagController = TextEditingController(
      text: _sourceBagLabel(widget.sourceBag),
    );
    _newBagController = TextEditingController();
    _docketController = TextEditingController();
    _newBagFocusNode = FocusNode();
    _docketFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _sourceBagController.dispose();
    _newBagController.dispose();
    _docketController.dispose();
    _newBagFocusNode.dispose();
    _docketFocusNode.dispose();
    super.dispose();
  }

  static String _sourceBagLabel(OutboundBagRow? row) {
    if (row == null) return '';
    final code = row.bagCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    final seal = row.metalSealNo?.trim();
    if (seal != null && seal.isNotEmpty) return seal;
    return '';
  }

  Future<void> _submit() async {
    final newBag = _newBagController.text.trim();
    final docket = _docketController.text.trim();
    if (newBag.isEmpty || docket.isEmpty) {
      Get.snackbar('Bagging', OutboundLabels.rebagValidationMessage);
      return;
    }
    Get.back();
    await widget.onSubmit(newBagCode: newBag, docketNo: docket);
  }

  @override
  Widget build(BuildContext context) {
    final sourceLabel = _sourceBagController.text.trim();

    return OutboundAdminSection(
      title: OutboundLabels.sectionRebag,
      children: [
        Text(
          OutboundLabels.subtitleRebag,
          style: themes.fontSize14_400.copyWith(
            color: themes.grayColor,
            fontSize: 11.5.sp,
          ),
        ),
        if (sourceLabel.isNotEmpty)
          OutboundLabeledFieldRow(
            label: OutboundLabels.sourceBagCode,
            child: OutboundReadOnlyInput(
              controller: _sourceBagController,
              copyable: true,
              snackbarTitle: 'Bagging',
            ),
          ),
        OutboundLabeledFieldRow(
          label: OutboundLabels.newBagCode,
          required: true,
          child: OutboundScanField(
            controller: _newBagController,
            focusNode: _newBagFocusNode,
            hintText: OutboundLabels.hintNewBagCode,
            prefixIcon: const Icon(CupertinoIcons.cube_box),
            onSubmitted: (_) => _docketFocusNode.requestFocus(),
            onScanned: (value) async {
              if (value.trim().isEmpty || value == '-1') return;
              _newBagController.text = value.trim();
              _docketFocusNode.requestFocus();
            },
          ),
        ),
        OutboundLabeledFieldRow(
          label: OutboundLabels.removeRebagDocket,
          required: true,
          child: OutboundScanField(
            controller: _docketController,
            focusNode: _docketFocusNode,
            hintText: OutboundLabels.scanDocketNo,
            prefixIcon: const Icon(CupertinoIcons.barcode),
            onSubmitted: (_) => _submit(),
            onScanned: (value) async {
              if (value.trim().isEmpty || value == '-1') return;
              _docketController.text = value.trim();
              await _submit();
            },
          ),
        ),
        OutboundSecondaryPrimaryRow(
          secondaryLabel: OutboundLabels.btnCancel,
          primaryTitle: OutboundLabels.btnRebag,
          onSecondary: () => Get.back(),
          onPrimary: _submit,
        ),
      ],
    );
  }
}
