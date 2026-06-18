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
    this.gstNo,
    this.items = const [],
  });

  /// Fallback when API omits `gst_no` (legacy responses).
  static const defaultGstNo = '27AAQCA4042D1ZU';
  static const companyWebsite = 'www.axlpl.com';
  static const companyEmail = 'info@axlpl.com';
  static const companyName = 'AMBE XPRESS LOGISTICS PVT LTD';

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
  final String? gstNo;
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
      gstNo: OutboundDataParse.firstNonEmptyString(json, const [
        'gst_no',
        'gstn',
        'gst_number',
      ]),
      items: BaggingReportItem.listFromDynamic(json['items']),
    );
  }

  factory BaggingReport.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map == null) return const BaggingReport();
    final nested = OutboundDataParse.asStringKeyedMap(map['data']);
    if (nested != null &&
        (nested.containsKey('bag_code') ||
            nested.containsKey('items') ||
            nested.containsKey('metal_seal_no'))) {
      return BaggingReport.fromJson(nested);
    }
    return BaggingReport.fromJson(map);
  }

  double get totalWeightValue =>
      items.fold(0.0, (sum, item) => sum + item.weightValue);

  int get totalPcsValue =>
      items.fold(0, (sum, item) => sum + item.pcsValue);

  String get totalWeightDisplay {
    final v = totalWeightValue;
    if (v == 0 && items.isEmpty) return '0';
    return v == v.roundToDouble() ? v.toStringAsFixed(2) : v.toStringAsFixed(2);
  }

  String get totalPcsDisplay => '${totalPcsValue}';

  /// Dynamic GST from API (`gst_no`); static fallback for older payloads.
  String get gstDisplay {
    final v = gstNo?.trim();
    if (v != null && v.isNotEmpty) return v;
    return defaultGstNo;
  }

  /// Admin print header: `GSTN: … | Website: … | Email: …`
  String get companyHeaderLine =>
      'GSTN: $gstDisplay | Website: $companyWebsite | Email: $companyEmail';

  /// Display name for PDF — API `created_by_name` or messenger profile name.
  String createdByLabel(String? messengerName) {
    final api = createdByName?.trim();
    if (api != null && api.isNotEmpty) return api;
    final local = messengerName?.trim();
    if (local != null && local.isNotEmpty) return local;
    return '—';
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
        if (gstNo != null) 'gst_no': gstNo,
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
