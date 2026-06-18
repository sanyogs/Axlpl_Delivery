import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Raw object from `getmanifestdetails` GET.
class ManifestDetail {
  const ManifestDetail({
    this.id,
    this.manifestNo,
    this.originBranch,
    this.destinationBranch,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.originBranchName,
    this.destinationBranchName,
    this.totalWeight,
    this.bags = const [],
    this.shipments = const [],
  });

  final String? id;
  final String? manifestNo;
  final String? originBranch;
  final String? destinationBranch;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final String? originBranchName;
  final String? destinationBranchName;
  final String? totalWeight;
  final List<ManifestBagRef> bags;
  final List<ManifestShipmentRef> shipments;

  String? get manifestId => id;

  String? get originBranchId => originBranch;

  String? get destinationBranchId => destinationBranch;

  String? get status => null;

  bool get hasContent {
    if (manifestNo?.trim().isNotEmpty ?? false) return true;
    if (bags.isNotEmpty || shipments.isNotEmpty) return true;
    if (id?.trim().isNotEmpty ?? false) {
      final hasOrigin = originBranch?.trim().isNotEmpty ?? false;
      final hasDest = destinationBranch?.trim().isNotEmpty ?? false;
      return hasOrigin && hasDest;
    }
    return false;
  }

  factory ManifestDetail.fromJson(Map<String, dynamic> json) {
    return ManifestDetail(
      id: OutboundDataParse.optionalString(json, 'id'),
      manifestNo: OutboundDataParse.firstNonEmptyString(json, const [
        'manifest_no',
        'manifest_code',
        'manifest_number',
      ]),
      originBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch_id',
        'origin_branch',
        'origin_branchId',
      ]),
      destinationBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_branch_id',
        'destination_branch',
        'destination_sector_id',
        'destination_branchId',
      ]),
      createdBy: OutboundDataParse.optionalString(json, 'created_by'),
      createdAt: OutboundDataParse.optionalString(json, 'created_at'),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
      originBranchName: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch_name',
        'origin_branch',
        'originBranchName',
      ]),
      destinationBranchName: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_branch_name',
        'destination_branch',
        'destination_sector_name',
        'destination_sector',
        'destinationBranchName',
      ]),
      totalWeight: OutboundDataParse.firstNonEmptyString(json, const [
        'total_weight',
        'gross_weight',
        'total_gross_weight',
      ]),
      bags: ManifestBagRef.listFromDynamic(json['bags']),
      shipments: ManifestShipmentRef.listFromDynamic(json['shipments']),
    );
  }

  factory ManifestDetail.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map == null) return const ManifestDetail();
    if (_looksLikeManifestDetail(map)) return ManifestDetail.fromJson(map);
    for (final key in const [
      'manifest',
      'manifest_detail',
      'details',
      'data'
    ]) {
      final nested = OutboundDataParse.asStringKeyedMap(map[key]);
      if (nested != null && _looksLikeManifestDetail(nested)) {
        return ManifestDetail.fromJson(nested);
      }
    }
    return ManifestDetail.fromJson(map);
  }

  static bool _looksLikeManifestDetail(Map<String, dynamic> map) {
    return map.containsKey('manifest_no') ||
        map.containsKey('manifest_code') ||
        map.containsKey('bags') ||
        map.containsKey('shipments');
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (manifestNo != null) 'manifest_no': manifestNo,
        if (originBranch != null) 'origin_branch': originBranch,
        if (destinationBranch != null) 'destination_branch': destinationBranch,
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        if (originBranchName != null) 'origin_branch_name': originBranchName,
        if (destinationBranchName != null)
          'destination_branch_name': destinationBranchName,
        'bags': bags.map((e) => e.toJson()).toList(),
        'shipments': shipments.map((e) => e.toJson()).toList(),
      };

  dynamic get rawForDisplay => toJson();

  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) lines.add('$label: $value');
    }

    add('Manifest', manifestNo);
    add('Id', id);
    add('Origin', originBranchName ?? originBranch);
    add('Destination', destinationBranchName ?? destinationBranch);
    add('Created', createdAt);
    for (final bag in bags) {
      if (bag.bagCode != null) lines.add('  • Bag ${bag.bagCode}');
    }
    for (final s in shipments) {
      if (s.id != null) {
        lines.add(
          '  • Shipment ${s.id} — ${s.shipmentStatus ?? ''} (bag ${s.bagCode ?? s.bagId ?? ''})',
        );
      }
    }
    return lines;
  }
}
