import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Raw POST response from `lockbag` (no `{status: success}` envelope).
class LockBagResponse {
  const LockBagResponse({
    this.bagId,
    this.bagCode,
    this.status,
  });

  final String? bagId;
  final String? bagCode;
  final String? status;

  bool get isLocked => status?.trim().toLowerCase() == 'locked';

  factory LockBagResponse.fromJson(Map<String, dynamic> json) {
    return LockBagResponse(
      bagId: OutboundDataParse.optionalString(json, 'bag_id'),
      bagCode: OutboundDataParse.optionalString(json, 'bag_code'),
      status: OutboundDataParse.optionalString(json, 'status'),
    );
  }

  factory LockBagResponse.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return LockBagResponse.fromJson(map);
    return const LockBagResponse();
  }

  Map<String, dynamic> toJson() => {
        if (bagId != null) 'bag_id': bagId,
        if (bagCode != null) 'bag_code': bagCode,
        if (status != null) 'status': status,
      };
}
