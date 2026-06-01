import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Manifest row inside `getlinehauldetails` → `manifests[]`.
class LinehaulManifestRef {
  const LinehaulManifestRef({
    this.id,
    this.manifestNo,
    this.originBranch,
    this.destinationBranch,
    this.createdAt,
  });

  final String? id;
  final String? manifestNo;
  final String? originBranch;
  final String? destinationBranch;
  final String? createdAt;

  factory LinehaulManifestRef.fromJson(Map<String, dynamic> json) {
    return LinehaulManifestRef(
      id: OutboundDataParse.optionalString(json, 'id'),
      manifestNo: OutboundDataParse.firstNonEmptyString(json, const [
        'manifest_no',
        'manifest_code',
        'code',
      ]),
      originBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch',
        'origin_branch_id',
      ]),
      destinationBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_branch',
        'destination_branch_id',
      ]),
      createdAt: OutboundDataParse.optionalString(json, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (manifestNo != null) 'manifest_no': manifestNo,
        if (originBranch != null) 'origin_branch': originBranch,
        if (destinationBranch != null) 'destination_branch': destinationBranch,
        if (createdAt != null) 'created_at': createdAt,
      };

  static List<LinehaulManifestRef> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, LinehaulManifestRef.fromJson);
}
