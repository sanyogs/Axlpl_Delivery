import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `listbags` inner `data` (list of bag maps).
class OutboundBagRow {
  const OutboundBagRow(this.raw);

  final Map<String, dynamic> raw;

  factory OutboundBagRow.fromJson(Map<String, dynamic> json) => OutboundBagRow(json);

  String? get bagId =>
      OutboundDataParse.firstNonEmptyString(raw, const ['bag_id', 'id', 'bagId']);

  String? get bagCode =>
      OutboundDataParse.firstNonEmptyString(raw, const ['bag_code', 'code', 'bagCode']);

  String? get status =>
      OutboundDataParse.firstNonEmptyString(raw, const ['status', 'bag_status']);

  String? get originBranchId => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['origin_branch_id', 'origin_branch', 'originBranchId'],
      );

  String? get destinationBranchId => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['destination_branch_id', 'destination_branch', 'destinationBranchId'],
      );

  Map<String, dynamic> get asMap => raw;

  static List<OutboundBagRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, OutboundBagRow.fromJson);
}
