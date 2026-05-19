import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Raw object from `baggingreport` GET (same shape as bag detail + report fields).
class BaggingReport {
  const BaggingReport({
    this.id,
    this.bagCode,
    this.metalSealNo,
    this.originBranchId,
    this.destinationSectorId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.originBranchName,
    this.destinationCityName,
    this.createdByName,
    this.items = const [],
  });

  final String? id;
  final String? bagCode;
  final String? metalSealNo;
  final String? originBranchId;
  final String? destinationSectorId;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final String? originBranchName;
  final String? destinationCityName;
  final String? createdByName;
  final List<BaggingReportItem> items;

  factory BaggingReport.fromJson(Map<String, dynamic> json) {
    return BaggingReport(
      id: OutboundDataParse.optionalString(json, 'id'),
      bagCode: OutboundDataParse.firstNonEmptyString(json, const [
        'bag_code',
        'code',
      ]),
      metalSealNo: OutboundDataParse.firstNonEmptyString(json, const [
        'metal_seal_no',
        'metal_seal',
      ]),
      originBranchId: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch_id',
        'origin_branch',
      ]),
      destinationSectorId: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_sector_id',
        'destination_branch_id',
      ]),
      createdBy: OutboundDataParse.optionalString(json, 'created_by'),
      createdAt: OutboundDataParse.optionalString(json, 'created_at'),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
      originBranchName: OutboundDataParse.optionalString(json, 'origin_branch_name'),
      destinationCityName:
          OutboundDataParse.optionalString(json, 'destination_city_name'),
      createdByName: OutboundDataParse.optionalString(json, 'created_by_name'),
      items: BaggingReportItem.listFromDynamic(json['items']),
    );
  }

  factory BaggingReport.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return BaggingReport.fromJson(map);
    return const BaggingReport();
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
        if (originBranchName != null) 'origin_branch_name': originBranchName,
        if (destinationCityName != null)
          'destination_city_name': destinationCityName,
        if (createdByName != null) 'created_by_name': createdByName,
        'items': items.map((e) => e.toJson()).toList(),
      };

  dynamic get rawForDisplay => toJson();

  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) lines.add('$label: $value');
    }

    add('Bag code', bagCode);
    add('Metal seal', metalSealNo);
    add('Origin', originBranchName ?? originBranchId);
    add('Destination city', destinationCityName ?? destinationSectorId);
    add('Created', createdAt);
    for (final item in items) {
      final sid = item.shipmentId;
      if (sid != null && sid.isNotEmpty) {
        lines.add(
          '  • $sid — ${item.receiverName ?? item.senderName ?? ''} '
          '(${item.destinationCity ?? ''}, ${item.totalWeight ?? ''} kg)',
        );
      }
    }
    return lines;
  }
}
