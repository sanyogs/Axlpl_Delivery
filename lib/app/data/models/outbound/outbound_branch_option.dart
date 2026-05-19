import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Branch / hub row for outbound dropdowns (hub scan, bagging, manifest).
class OutboundBranchOption {
  const OutboundBranchOption({
    required this.id,
    required this.label,
    this.code,
  });

  final String id;
  final String label;
  final String? code;

  factory OutboundBranchOption.fromJson(Map<String, dynamic> json) {
    final id = OutboundDataParse.firstNonEmptyString(json, const [
          'branch_id',
          'id',
          'branchId',
          'hub_id',
          'hubId',
          'value',
        ]) ??
        '';
    final label = OutboundDataParse.firstNonEmptyString(json, const [
          'branch_name',
          'name',
          'label',
          'branch',
          'hub_name',
          'hub',
          'city_name',
          'city',
          'title',
          'text',
        ]) ??
        id;
    final code = OutboundDataParse.firstNonEmptyString(json, const [
      'branch_code',
      'code',
      'hub_code',
    ]);
    return OutboundBranchOption(id: id, label: label, code: code);
  }

  static List<OutboundBranchOption> listFromDynamic(dynamic data) {
    final rows =
        OutboundDataParse.mapListFromDynamic(data, OutboundBranchOption.fromJson);
    final seen = <String>{};
    final out = <OutboundBranchOption>[];
    for (final row in rows) {
      if (row.id.isEmpty) continue;
      if (!seen.add(row.id)) continue;
      out.add(row);
    }
    out.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return out;
  }

  static OutboundBranchOption? fromMessenger({
    String? branchId,
    String? branchName,
  }) {
    final id = branchId?.trim();
    if (id == null || id.isEmpty) return null;
    final name = branchName?.trim();
    return OutboundBranchOption(
      id: id,
      label: (name != null && name.isNotEmpty) ? name : id,
    );
  }
}
