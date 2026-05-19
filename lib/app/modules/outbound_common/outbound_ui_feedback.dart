import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_repository_retry.dart';
import 'package:get/get.dart';

/// Shared snackbar + pretty JSON for outbound submodule screens.
class OutboundUiFeedback {
  OutboundUiFeedback._();

  static void apply({
    required RxString target,
    required APIResponse response,
    required String feature,
  }) {
    response.when(
      success: (data) {
        target.value = OutboundDataParse.pretty(data);
        if (OutboundDataParse.isNonJsonBody(data)) {
          Get.snackbar(
            feature,
            'Success — non-JSON body (report/print). Raw text below.',
          );
        } else {
          Get.snackbar(feature, 'Success');
        }
      },
      error: (e) {
        target.value = e.message;
        final msg = e.message;
        if (outboundIsBenignDuplicate(msg)) {
          Get.snackbar(feature, 'Already recorded — $msg');
        } else {
          Get.snackbar(feature, msg);
        }
      },
    );
  }
}
