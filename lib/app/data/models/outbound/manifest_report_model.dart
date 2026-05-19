import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Raw object from `manifestreport` GET.
class ManifestReport {
  const ManifestReport({
    this.id,
    this.manifestNo,
    this.originBranch,
    this.destinationBranch,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.originBranchName,
    this.originName,
    this.destinationBranchName,
    this.destinationName,
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
  final String? originName;
  final String? destinationBranchName;
  final String? destinationName;
  final List<ManifestBagRef> bags;
  final List<ManifestShipmentRef> shipments;

  factory ManifestReport.fromJson(Map<String, dynamic> json) {
    return ManifestReport(
      id: OutboundDataParse.optionalString(json, 'id'),
      manifestNo: OutboundDataParse.firstNonEmptyString(json, const [
        'manifest_no',
        'manifest_code',
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
      originBranchName:
          OutboundDataParse.optionalString(json, 'origin_branch_name'),
      originName: OutboundDataParse.optionalString(json, 'origin_name'),
      destinationBranchName:
          OutboundDataParse.optionalString(json, 'destination_branch_name'),
      destinationName: OutboundDataParse.optionalString(json, 'destination_name'),
      bags: ManifestBagRef.listFromDynamic(json['bags']),
      shipments: ManifestShipmentRef.listFromDynamic(json['shipments']),
    );
  }

  factory ManifestReport.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return ManifestReport.fromJson(map);
    return const ManifestReport();
  }

  dynamic get rawForDisplay => toJson();

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (manifestNo != null) 'manifest_no': manifestNo,
        if (originBranch != null) 'origin_branch': originBranch,
        if (destinationBranch != null) 'destination_branch': destinationBranch,
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        if (originBranchName != null) 'origin_branch_name': originBranchName,
        if (originName != null) 'origin_name': originName,
        if (destinationBranchName != null)
          'destination_branch_name': destinationBranchName,
        if (destinationName != null) 'destination_name': destinationName,
        'bags': bags.map((e) => e.toJson()).toList(),
        'shipments': shipments.map((e) => e.toJson()).toList(),
      };

  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) lines.add('$label: $value');
    }

    add('Manifest', manifestNo);
    add('Origin', originName ?? originBranchName ?? originBranch);
    add('Destination', destinationName ?? destinationBranchName ?? destinationBranch);
    add('Created', createdAt);
    for (final bag in bags) {
      if (bag.bagCode != null) {
        lines.add(
          '  • Bag ${bag.bagCode} — seal ${bag.metalSealNo ?? ''} '
          '(${bag.grossWeight ?? ''} kg)',
        );
      }
    }
    for (final s in shipments) {
      if (s.id != null) {
        lines.add(
          '  • Shipment ${s.id} — ${s.receiverName ?? s.senderName ?? ''} '
          '(${s.destinationCity ?? ''}, ${s.grossWeight ?? ''} kg)',
        );
      }
    }
    return lines;
  }
}
