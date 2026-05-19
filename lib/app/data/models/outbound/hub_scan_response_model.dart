import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Raw POST response from `hubscan` (no `{status: success}` envelope).
class HubScanResponse {
  const HubScanResponse({
    this.successMessage,
    this.shipmentId,
    this.docketNo,
  });

  /// Server field is named `success` (human-readable message).
  final String? successMessage;
  final String? shipmentId;
  final String? docketNo;

  bool get isOk =>
      successMessage != null && successMessage!.trim().isNotEmpty;

  factory HubScanResponse.fromJson(Map<String, dynamic> json) {
    return HubScanResponse(
      successMessage: OutboundDataParse.optionalString(json, 'success'),
      shipmentId: OutboundDataParse.firstNonEmptyString(json, const [
        'shipment_id',
        'docket_no',
        's_id',
      ]),
      docketNo: OutboundDataParse.optionalString(json, 'docket_no'),
    );
  }

  factory HubScanResponse.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return HubScanResponse.fromJson(map);
    return const HubScanResponse();
  }

  Map<String, dynamic> toJson() => {
        if (successMessage != null) 'success': successMessage,
        if (shipmentId != null) 'shipment_id': shipmentId,
        if (docketNo != null) 'docket_no': docketNo,
      };
}
