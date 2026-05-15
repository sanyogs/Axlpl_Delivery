import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `listmanifests` inner `data`.
class OutboundManifestRow {
  const OutboundManifestRow(this.raw);

  final Map<String, dynamic> raw;

  factory OutboundManifestRow.fromJson(Map<String, dynamic> json) =>
      OutboundManifestRow(json);

  String? get manifestId => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['manifest_id', 'id', 'manifestId'],
      );

  String? get manifestNo => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['manifest_no', 'manifest_number', 'manifestNo'],
      );

  String? get status =>
      OutboundDataParse.firstNonEmptyString(raw, const ['status']);

  String? get originBranchId => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['origin_branch_id', 'origin_branch', 'originBranchId'],
      );

  String? get destinationBranchId => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['destination_branch_id', 'destination_branch', 'destinationBranchId'],
      );

  Map<String, dynamic> get asMap => raw;

  static List<OutboundManifestRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, OutboundManifestRow.fromJson);
}
