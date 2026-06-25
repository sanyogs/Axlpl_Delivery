import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Response from `getpickupdetail`.
class PickupDetail {
  const PickupDetail({
    this.id,
    this.mawbNo,
    this.hubId,
    this.originHub,
    this.destinationHub,
    this.originBranch,
    this.destinationBranch,
    this.flightNo,
    this.pickupDate,
    this.pickupTime,
    this.pickedBy,
    this.totalShipments,
    this.createdAt,
    this.updatedAt,
    this.shipmentList = const [],
  });

  final String? id;
  final String? mawbNo;
  final String? hubId;
  final String? originHub;
  final String? destinationHub;
  final String? originBranch;
  final String? destinationBranch;
  final String? flightNo;
  final String? pickupDate;
  final String? pickupTime;
  final String? pickedBy;
  final int? totalShipments;
  final String? createdAt;
  final String? updatedAt;
  final List<PickupDetailShipment> shipmentList;

  String get hubBranchLabel {
    final hub = originHub?.trim();
    if (hub != null && hub.isNotEmpty) return hub;
    final branch = originBranch?.trim();
    if (branch != null && branch.isNotEmpty) return branch;
    return hubId?.trim().isNotEmpty == true ? hubId!.trim() : '—';
  }

  String get pickupDateTimeLabel {
    final date = pickupDate?.trim();
    final time = pickupTime?.trim();
    if (date == null || date.isEmpty) return '—';
    if (time == null || time.isEmpty) return date;
    return '$date $time';
  }

  int get manifestedCount =>
      totalShipments ?? shipmentList.length;

  factory PickupDetail.fromJson(Map<String, dynamic> json) {
    return PickupDetail(
      id: OutboundDataParse.firstNonEmptyString(json, const ['id', 'pickup_id']),
      mawbNo: OutboundDataParse.optionalString(json, 'mawb_no'),
      hubId: OutboundDataParse.optionalString(json, 'hub_id'),
      originHub: OutboundDataParse.optionalString(json, 'origin_hub'),
      destinationHub: OutboundDataParse.optionalString(json, 'destination_hub'),
      originBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch',
        'origin_branch_name',
      ]),
      destinationBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_branch',
        'destination_branch_name',
      ]),
      flightNo: OutboundDataParse.optionalString(json, 'flight_no'),
      pickupDate: OutboundDataParse.optionalString(json, 'pickup_date'),
      pickupTime: OutboundDataParse.optionalString(json, 'pickup_time'),
      pickedBy: OutboundDataParse.optionalString(json, 'picked_by'),
      totalShipments: OutboundDataParse.optionalInt(json, 'total_shipments'),
      createdAt: OutboundDataParse.optionalString(json, 'created_at'),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
      shipmentList: PickupDetailShipment.listFromDynamic(json['shipment_list']),
    );
  }

  factory PickupDetail.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return PickupDetail.fromJson(map);
    return const PickupDetail();
  }
}

class PickupDetailShipment {
  const PickupDetailShipment({
    this.shipmentId,
    this.shipmentInvoiceNo,
    this.status,
    this.senderName,
    this.receiverName,
    this.bagCode,
    this.metalSealNo,
    this.destHub,
    this.packets,
    this.consigneeCode,
  });

  final String? shipmentId;
  final String? shipmentInvoiceNo;
  final String? status;
  final String? senderName;
  final String? receiverName;
  final String? bagCode;
  final String? metalSealNo;
  final String? destHub;
  final String? packets;
  final String? consigneeCode;

  String get docketNo {
    final id = shipmentId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return shipmentInvoiceNo?.trim() ?? '';
  }

  String get bagGroupKey {
    final bag = bagCode?.trim();
    if (bag != null && bag.isNotEmpty) return bag;
    final seal = metalSealNo?.trim();
    if (seal != null && seal.isNotEmpty) return seal;
    return '';
  }

  String get displayCodeSuffix {
    final invoice = shipmentInvoiceNo?.trim();
    if (invoice != null && invoice.isNotEmpty) return invoice;
    final code = consigneeCode?.trim();
    if (code != null && code.isNotEmpty) return code;
    final st = status?.trim();
    if (st != null && st.isNotEmpty) return st;
    return '—';
  }

  String get packetsDisplay {
    final pkgs = packets?.trim();
    if (pkgs != null && pkgs.isNotEmpty) return pkgs;
    return '1';
  }

  String get destHubDisplay {
    final hub = destHub?.trim();
    if (hub != null && hub.isNotEmpty) return hub;
    return '—';
  }

  factory PickupDetailShipment.fromJson(Map<String, dynamic> json) {
    return PickupDetailShipment(
      shipmentId: OutboundDataParse.firstNonEmptyString(json, const [
        'shipment_id',
        'docket_no',
        'id',
      ]),
      shipmentInvoiceNo:
          OutboundDataParse.optionalString(json, 'shipment_invoice_no'),
      status: OutboundDataParse.firstNonEmptyString(json, const [
        'status',
        'shipment_status',
      ]),
      senderName: OutboundDataParse.optionalString(json, 'sender_name'),
      receiverName: OutboundDataParse.optionalString(json, 'receiver_name'),
      bagCode: OutboundDataParse.firstNonEmptyString(json, const [
        'bag_code',
        'bag_no',
      ]),
      metalSealNo: OutboundDataParse.firstNonEmptyString(json, const [
        'metal_seal_no',
        'bag_seal',
        'seal_no',
      ]),
      destHub: OutboundDataParse.firstNonEmptyString(json, const [
        'dest_hub',
        'destination_hub',
        'destination_city',
        'destination_branch',
        'destination_branch_name',
      ]),
      packets: OutboundDataParse.firstNonEmptyString(json, const [
        'packets',
        'pkgs',
        'no_of_package',
        'number_of_parcel',
      ]),
      consigneeCode: OutboundDataParse.firstNonEmptyString(json, const [
        'consignee_code',
        'sector_code',
        'entry_no',
      ]),
    );
  }

  static List<PickupDetailShipment> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, PickupDetailShipment.fromJson);
}

/// Bag-level grouping for sector pickup report PDF.
class SectorPickupReportBagGroup {
  const SectorPickupReportBagGroup({
    required this.slNo,
    required this.bagLabel,
    required this.destHub,
    required this.shipmentCount,
    required this.packetCount,
    required this.shipments,
    this.isLooseGroup = false,
  });

  final int slNo;
  final String bagLabel;
  final String destHub;
  final int shipmentCount;
  final int packetCount;
  final List<PickupDetailShipment> shipments;
  final bool isLooseGroup;

  static List<SectorPickupReportBagGroup> fromPickupDetail(PickupDetail detail) {
    final shipments = detail.shipmentList;
    if (shipments.isEmpty) return const [];

    final grouped = <String, List<PickupDetailShipment>>{};
    for (final shipment in shipments) {
      final key = shipment.bagGroupKey;
      grouped.putIfAbsent(key, () => []).add(shipment);
    }

    final hasBagGroups =
        grouped.keys.any((key) => key.trim().isNotEmpty) && grouped.length > 1;

    if (!hasBagGroups) {
      final looseKey = grouped.keys.first;
      final looseShipments = grouped[looseKey] ?? shipments;
      final packetTotal = looseShipments.fold<int>(
        0,
        (sum, s) => sum + (int.tryParse(s.packetsDisplay) ?? 1),
      );
      return [
        SectorPickupReportBagGroup(
          slNo: 1,
          bagLabel: 'Loose shipments',
          destHub: 'N/A',
          shipmentCount: looseShipments.length,
          packetCount: packetTotal,
          shipments: looseShipments,
          isLooseGroup: true,
        ),
      ];
    }

    final out = <SectorPickupReportBagGroup>[];
    var sl = 0;
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty) return 1;
        if (b.isEmpty) return -1;
        return a.compareTo(b);
      });

    for (final key in sortedKeys) {
      final rows = grouped[key] ?? const [];
      if (rows.isEmpty) continue;
      sl++;
      final label = key.isEmpty ? 'Loose shipments' : key;
      final dest = key.isEmpty
          ? 'N/A'
          : (rows.first.destHubDisplay != '—'
              ? rows.first.destHubDisplay
              : detail.destinationHub ?? detail.destinationBranch ?? '—');
      final packetTotal = rows.fold<int>(
        0,
        (sum, s) => sum + (int.tryParse(s.packetsDisplay) ?? 1),
      );
      out.add(
        SectorPickupReportBagGroup(
          slNo: sl,
          bagLabel: label,
          destHub: dest,
          shipmentCount: rows.length,
          packetCount: packetTotal,
          shipments: rows,
          isLooseGroup: key.isEmpty,
        ),
      );
    }
    return out;
  }
}
