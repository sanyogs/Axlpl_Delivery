import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Inner `data` from `getmanifestdetails` after [ApiClient] unwrap.
class ManifestDetail {
  const ManifestDetail(this.inner);

  final dynamic inner;

  factory ManifestDetail.fromDynamic(dynamic data) => ManifestDetail(data);

  Map<String, dynamic>? get asMap => OutboundDataParse.asStringKeyedMap(inner);

  String? get manifestId => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['manifest_id', 'id', 'manifestId'],
      );

  String? get manifestNo => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['manifest_no', 'manifest_number', 'manifestNo'],
      );

  String? get status =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['status']);

  String? get originBranchId => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['origin_branch_id', 'origin_branch', 'originBranchId'],
      );

  String? get destinationBranchId => OutboundDataParse.firstNonEmptyString(
        asMap,
        const [
          'destination_branch_id',
          'destination_branch',
          'destinationBranchId',
        ],
      );

  String? get createdAt => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['created_at', 'createdAt'],
      );

  dynamic get rawForDisplay => inner;

  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) lines.add('$label: $value');
    }
    add('Manifest id', manifestId);
    add('Manifest no', manifestNo);
    add('Status', status);
    add('Origin branch', originBranchId);
    add('Destination branch', destinationBranchId);
    add('Created at', createdAt);
    return lines;
  }
}
