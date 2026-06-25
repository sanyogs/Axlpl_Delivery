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
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.shipmentCount,
    this.manifestStatus,
    this.grossWeight,
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
  final String? createdByName;
  final String? createdAt;
  final String? updatedAt;
  final int? shipmentCount;
  final String? manifestStatus;
  final String? grossWeight;
  final List<BagDetailItem> items;

  /// Alias for numeric `id` when callers expect `bag_id`.
  String? get bagId => id;

  /// Alias for sector id used as destination in bagging flows.
  String? get destinationBranchId => destinationSectorId;

  String? get status => manifestStatus;

  String? get lockedAt => null;

  int get totalBoxes {
    var sum = 0;
    for (final item in items) {
      final pcs = int.tryParse(item.noOfPackage?.trim() ?? '');
      sum += pcs ?? 1;
    }
    if (sum > 0) return sum;
    return shipmentCount ?? items.length;
  }

  String get totalWeightDisplay {
    final bagWt = grossWeight?.trim();
    if (bagWt != null && bagWt.isNotEmpty) return bagWt;
    var sum = 0.0;
    for (final item in items) {
      final w = double.tryParse(item.totalWeight?.trim() ?? '');
      if (w != null) sum += w;
    }
    if (sum > 0) return sum.toStringAsFixed(2);
    return '—';
  }

  String get createdByDisplay {
    final name = createdByName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final id = createdBy?.trim();
    if (id != null && id.isNotEmpty) return id;
    return 'N/A';
  }

  bool get isOpenForChanges {
    final status = manifestStatus?.trim().toLowerCase() ?? '';
    if (status.isEmpty) return true;
    return !status.contains('lock');
  }

  int get shipmentCountDisplay => shipmentCount ?? items.length;

  static const _bagCodeKeys = [
    'bag_code',
    'code',
    'bagCode',
    'bag_no',
    'bag_number',
    'bagNumber',
    'm_bag_code',
    'mbag_code',
    'mBagCode',
    'm_bag_no',
    'mbag_no',
    'mBagNo',
  ];

  static const _metalSealKeys = [
    'metal_seal_no',
    'metal_seal',
    'seal_no',
  ];

  static const _scanMatchKeys = [
    ..._bagCodeKeys,
    ..._metalSealKeys,
    'bag_id',
    'id',
  ];

  /// Prefer server `bag_code` (e.g. BAG…) for table display and mutations.
  static String? resolveBagCode(
    Map<String, dynamic> json, {
    String? requestedBagCode,
  }) {
    final explicit = OutboundDataParse.firstNonEmptyString(json, _bagCodeKeys);
    if (explicit != null &&
        explicit.isNotEmpty &&
        explicit.toUpperCase().startsWith('BAG')) {
      return explicit;
    }

    final requested = requestedBagCode?.trim();
    if (requested != null && requested.isNotEmpty) {
      final requestedLower = requested.toLowerCase();
      for (final key in _scanMatchKeys) {
        final value = json[key]?.toString().trim();
        if (value != null &&
            value.isNotEmpty &&
            value.toLowerCase() == requestedLower) {
          return explicit ?? requested;
        }
      }
    }

    if (explicit != null) return explicit;

    return OutboundDataParse.firstNonEmptyString(json, _metalSealKeys);
  }

  factory BagDetail.fromJson(
    Map<String, dynamic> json, {
    String? requestedBagCode,
  }) {
    return BagDetail(
      id: OutboundDataParse.optionalString(json, 'id'),
      bagCode: resolveBagCode(json, requestedBagCode: requestedBagCode),
      metalSealNo: OutboundDataParse.firstNonEmptyString(json, _metalSealKeys),
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
        'destination_city_name',
        'destinationSectorName',
      ]),
      createdBy: OutboundDataParse.optionalString(json, 'created_by'),
      createdByName: OutboundDataParse.firstNonEmptyString(json, const [
        'created_by_name',
        'createdByName',
      ]),
      createdAt: OutboundDataParse.firstNonEmptyString(json, const [
        'created_at',
        'createdAt',
      ]),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
      shipmentCount: OutboundDataParse.optionalInt(json, 'shipment_count'),
      manifestStatus: OutboundDataParse.optionalString(json, 'manifest_status'),
      grossWeight: OutboundDataParse.firstNonEmptyString(json, const [
        'gross_weight',
        'total_weight',
      ]),
      items: BagDetailItem.listFromDynamic(json['items']),
    );
  }

  factory BagDetail.fromDynamic(
    dynamic data, {
    String? requestedBagCode,
  }) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map == null) {
      final listDetail = _bagDetailFromListPayload(
        data,
        requestedBagCode: requestedBagCode,
      );
      return listDetail != null
          ? BagDetail.fromJson(
              listDetail,
              requestedBagCode: requestedBagCode,
            )
          : const BagDetail();
    }

    final fromContainer = _bagDetailFromBagContainer(map);
    if (fromContainer != null) {
      return BagDetail.fromJson(
        fromContainer,
        requestedBagCode: requestedBagCode,
      );
    }

    if (_looksLikeBagDetail(map)) {
      return BagDetail.fromJson(map, requestedBagCode: requestedBagCode);
    }

    final listDetail = _bagDetailFromListPayload(
      map,
      requestedBagCode: requestedBagCode,
    );
    if (listDetail != null) {
      return BagDetail.fromJson(
        listDetail,
        requestedBagCode: requestedBagCode,
      );
    }

    for (final key in const [
      'data',
      'bag',
      'bag_detail',
      'details',
      'result',
      'bags',
    ]) {
      final nested = OutboundDataParse.asStringKeyedMap(map[key]);
      if (nested == null) continue;

      final nestedContainer = _bagDetailFromBagContainer(nested);
      if (nestedContainer != null) {
        return BagDetail.fromJson(
          nestedContainer,
          requestedBagCode: requestedBagCode,
        );
      }

      if (_looksLikeBagDetail(nested)) {
        return BagDetail.fromJson(
          nested,
          requestedBagCode: requestedBagCode,
        );
      }
      final nestedListDetail = _bagDetailFromListPayload(
        map[key],
        requestedBagCode: requestedBagCode,
      );
      if (nestedListDetail != null) {
        return BagDetail.fromJson(
          nestedListDetail,
          requestedBagCode: requestedBagCode,
        );
      }
    }
    return BagDetail.fromJson(map, requestedBagCode: requestedBagCode);
  }

  /// Live `getbagdetails` wraps bag fields under `data.bag` with sibling `items`.
  static Map<String, dynamic>? _bagDetailFromBagContainer(
    Map<String, dynamic> map,
  ) {
    for (final container in _bagContainerLevels(map)) {
      final bag = OutboundDataParse.asStringKeyedMap(container['bag']);
      if (bag == null) continue;
      final merged = Map<String, dynamic>.from(bag);
      final items = container['items'];
      if (items is List) merged['items'] = items;
      return merged;
    }
    return null;
  }

  static List<Map<String, dynamic>> _bagContainerLevels(
    Map<String, dynamic> map,
  ) {
    final levels = <Map<String, dynamic>>[map];
    final data = OutboundDataParse.asStringKeyedMap(map['data']);
    if (data != null) {
      levels.add(data);
      final inner = OutboundDataParse.asStringKeyedMap(data['data']);
      if (inner != null) levels.add(inner);
    }
    return levels;
  }

  static bool _looksLikeBagDetail(Map<String, dynamic> map) {
    return OutboundDataParse.firstNonEmptyString(map, _bagCodeKeys) != null ||
        map.containsKey('metal_seal_no') ||
        map.containsKey('shipment_count') ||
        (map.containsKey('origin_branch_id') &&
            map.containsKey('destination_sector_id'));
  }

  static Map<String, dynamic>? _bagDetailFromListPayload(
    dynamic payload, {
    String? requestedBagCode,
  }) {
    final rows = OutboundDataParse.asMapList(payload);
    if (rows.isEmpty) return null;

    final requested = requestedBagCode?.trim().toLowerCase();
    if (requested != null && requested.isNotEmpty) {
      for (final row in rows) {
        final code = OutboundDataParse.firstNonEmptyString(row, _scanMatchKeys);
        if (code != null && code.toLowerCase() == requested) {
          return row;
        }
      }
    }

    for (final row in rows) {
      if (_looksLikeBagDetail(row)) return row;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (bagCode != null) 'bag_code': bagCode,
        if (metalSealNo != null) 'metal_seal_no': metalSealNo,
        if (originBranchId != null) 'origin_branch_id': originBranchId,
        if (destinationSectorId != null)
          'destination_sector_id': destinationSectorId,
        if (createdBy != null) 'created_by': createdBy,
        if (createdByName != null) 'created_by_name': createdByName,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        if (shipmentCount != null) 'shipment_count': shipmentCount,
        if (manifestStatus != null) 'manifest_status': manifestStatus,
        if (grossWeight != null) 'gross_weight': grossWeight,
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
    add('Origin branch', originBranchName ?? originBranchId);
    add('Destination', destinationSectorName ?? destinationSectorId);
    add('Gross weight', grossWeight);
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
