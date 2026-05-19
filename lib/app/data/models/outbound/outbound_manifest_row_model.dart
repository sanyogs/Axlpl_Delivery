import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `listmanifests` (raw JSON array).
class OutboundManifestRow {
  const OutboundManifestRow({
    this.id,
    this.manifestNo,
    this.originBranch,
    this.destinationBranch,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? manifestNo;
  final String? originBranch;
  final String? destinationBranch;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  String? get manifestId => id;

  String? get originBranchId => originBranch;

  String? get destinationBranchId => destinationBranch;

  String? get status => null;

  factory OutboundManifestRow.fromJson(Map<String, dynamic> json) {
    return OutboundManifestRow(
      id: OutboundDataParse.optionalString(json, 'id'),
      manifestNo: OutboundDataParse.firstNonEmptyString(json, const [
        'manifest_no',
        'manifest_code',
        'manifest_number',
      ]),
      originBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch',
        'origin_branch_id',
      ]),
      destinationBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_branch',
        'destination_branch_id',
      ]),
      createdBy: OutboundDataParse.optionalString(json, 'created_by'),
      createdAt: OutboundDataParse.optionalString(json, 'created_at'),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (manifestNo != null) 'manifest_no': manifestNo,
        if (originBranch != null) 'origin_branch': originBranch,
        if (destinationBranch != null) 'destination_branch': destinationBranch,
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  Map<String, dynamic> get asMap => toJson();

  static List<OutboundManifestRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, OutboundManifestRow.fromJson);
}
