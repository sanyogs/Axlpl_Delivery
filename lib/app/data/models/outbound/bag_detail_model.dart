import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Response from `getbagdetails` (object with nested `items[]`).
class BagDetail {
  const BagDetail({
    this.id,
    this.bagCode,
    this.metalSealNo,
    this.originBranchId,
    this.originBranchName,
    this.destinationSectorId,
    this.destinationSectorName,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.shipmentCount,
    this.manifestStatus,
    this.items = const [],
  });

  final String? id;
  final String? bagCode;
  final String? metalSealNo;
  final String? originBranchId;
  final String? originBranchName;
  final String? destinationSectorId;
  final String? destinationSectorName;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final int? shipmentCount;
  final String? manifestStatus;
  final List<BagDetailItem> items;

  /// Alias for numeric `id` when callers expect `bag_id`.
  String? get bagId => id;

  /// Alias for sector id used as destination in bagging flows.
  String? get destinationBranchId => destinationSectorId;

  String? get status => manifestStatus;

  String? get lockedAt => null;

  factory BagDetail.fromJson(Map<String, dynamic> json) {
    return BagDetail(
      id: OutboundDataParse.optionalString(json, 'id'),
      bagCode: OutboundDataParse.firstNonEmptyString(json, const [
        'bag_code',
        'code',
        'bagCode',
      ]),
      metalSealNo: OutboundDataParse.firstNonEmptyString(json, const [
        'metal_seal_no',
        'metal_seal',
        'seal_no',
      ]),
      originBranchId: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch_id',
        'origin_branchId',
      ]),
      originBranchName: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch_name',
        'origin_branch',
        'originBranchName',
      ]),
      destinationSectorId: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_sector_id',
        'destination_branch_id',
        'destination_sectorId',
      ]),
      destinationSectorName: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_sector_name',
        'destination_sector',
        'destination_branch_name',
        'destination_branch',
        'destinationSectorName',
      ]),
      createdBy: OutboundDataParse.optionalString(json, 'created_by'),
      createdAt: OutboundDataParse.firstNonEmptyString(json, const [
        'created_at',
        'createdAt',
      ]),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
      shipmentCount: OutboundDataParse.optionalInt(json, 'shipment_count'),
      manifestStatus: OutboundDataParse.optionalString(json, 'manifest_status'),
      items: BagDetailItem.listFromDynamic(json['items']),
    );
  }

  factory BagDetail.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map == null) return const BagDetail();
    if (_looksLikeBagDetail(map)) return BagDetail.fromJson(map);
    for (final key in const ['bag', 'bag_detail', 'details', 'result']) {
      final nested = OutboundDataParse.asStringKeyedMap(map[key]);
      if (nested != null && _looksLikeBagDetail(nested)) {
        return BagDetail.fromJson(nested);
      }
    }
    return BagDetail.fromJson(map);
  }

  static bool _looksLikeBagDetail(Map<String, dynamic> map) {
    return map.containsKey('bag_code') ||
        map.containsKey('items') ||
        map.containsKey('metal_seal_no');
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (bagCode != null) 'bag_code': bagCode,
        if (metalSealNo != null) 'metal_seal_no': metalSealNo,
        if (originBranchId != null) 'origin_branch_id': originBranchId,
        if (destinationSectorId != null)
          'destination_sector_id': destinationSectorId,
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        if (shipmentCount != null) 'shipment_count': shipmentCount,
        if (manifestStatus != null) 'manifest_status': manifestStatus,
        'items': items.map((e) => e.toJson()).toList(),
      };

  /// Value suitable for [OutboundDataParse.pretty].
  dynamic get rawForDisplay => toJson();

  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) lines.add('$label: $value');
    }

    add('Bag code', bagCode);
    add('Bag id', id);
    add('Metal seal', metalSealNo);
    add('Manifest status', manifestStatus);
    if (shipmentCount != null) {
      lines.add('Shipments in bag: $shipmentCount');
    }
    add('Origin branch', originBranchId);
    add('Destination sector', destinationSectorId);
    add('Created', createdAt);
    add('Updated', updatedAt);
    for (final item in items) {
      final sid = item.shipmentId;
      if (sid != null && sid.isNotEmpty) {
        final inv = item.shipmentInvoiceNo;
        final st = item.shipmentStatus;
        lines.add(
          '  • Shipment $sid${inv != null ? ' ($inv)' : ''}${st != null ? ' — $st' : ''}',
        );
      }
    }
    return lines;
  }
}
