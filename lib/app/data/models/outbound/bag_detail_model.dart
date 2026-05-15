import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Inner `data` from `getbagdetails` after [ApiClient] unwrap (map, list, or non-JSON string).
class BagDetail {
  const BagDetail(this.inner);

  final dynamic inner;

  factory BagDetail.fromDynamic(dynamic data) => BagDetail(data);

  Map<String, dynamic>? get asMap => OutboundDataParse.asStringKeyedMap(inner);

  String? get bagId =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['bag_id', 'id', 'bagId']);

  String? get bagCode =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['bag_code', 'code', 'bagCode']);

  String? get status =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['status', 'bag_status']);

  String? get originBranchId => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['origin_branch_id', 'origin_branch', 'originBranchId'],
      );

  String? get destinationBranchId => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['destination_branch_id', 'destination_branch', 'destinationBranchId'],
      );

  String? get lockedAt =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['locked_at', 'lock_time']);

  /// Value suitable for [OutboundDataParse.pretty].
  dynamic get rawForDisplay => inner;

  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) lines.add('$label: $value');
    }
    add('Bag id', bagId);
    add('Bag code', bagCode);
    add('Status', status);
    add('Origin branch', originBranchId);
    add('Destination branch', destinationBranchId);
    add('Locked at', lockedAt);
    return lines;
  }
}
