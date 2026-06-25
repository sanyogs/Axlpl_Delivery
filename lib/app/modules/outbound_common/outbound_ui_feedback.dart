import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:get/get.dart';

/// Shared snackbar + response text for outbound submodule screens.
class OutboundUiFeedback {
  OutboundUiFeedback._();

  static const _serverMessageKey = '__server_message';

  /// Reads server `message` injected by [ApiClient._unwrapSuccessPayload] or on payload.
  static String? serverMessageFromData(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map == null) return null;
    final injected = OutboundDataParse.optionalString(map, _serverMessageKey);
    if (injected != null && injected.isNotEmpty) return injected;
    return OutboundDataParse.optionalString(map, 'message');
  }

  static void apply({
    required RxString target,
    required APIResponse response,
    required String feature,
    /// When true: only show API `message` (snackbar + panel). No client "Success" or pretty JSON.
    bool serverMessageOnly = false,
    /// Table/report reads should keep messages inline — no snackbar popups.
    bool showSnackbar = true,
  }) {
    response.when(
      success: (data) {
        if (serverMessageOnly) {
          final msg = serverMessageFromData(data) ?? '';
          target.value = msg;
          if (showSnackbar && msg.isNotEmpty) {
            Get.snackbar(feature, msg);
          }
          return;
        }
        target.value = OutboundDataParse.pretty(data);
        if (!showSnackbar) return;
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
        final msg = e.message.trim();
        if (serverMessageOnly) {
          target.value = msg;
          if (showSnackbar && msg.isNotEmpty) {
            Get.snackbar(feature, msg);
          }
          return;
        }
        target.value = msg;
        if (showSnackbar && msg.isNotEmpty) {
          Get.snackbar(feature, msg);
        }
      },
    );
  }
}
