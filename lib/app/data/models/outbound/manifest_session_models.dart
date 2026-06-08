import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// One scanned M/Bag in the manifest create session (`getbagdetails`).
class ManifestBagSessionRow {
  const ManifestBagSessionRow({
    required this.bagCode,
    required this.originLabel,
    required this.destinationLabel,
    required this.detail,
    this.weight,
  });

  final String bagCode;
  final String originLabel;
  final String destinationLabel;
  final BagDetail detail;
  final String? weight;

  factory ManifestBagSessionRow.fromBagDetail(
    BagDetail detail, {
    required String Function(String? id) branchLabel,
    dynamic rawData,
  }) {
    final code = detail.bagCode?.trim() ?? '';
    final origin = _branchDisplay(
      name: detail.originBranchName,
      id: detail.originBranchId,
      branchLabel: branchLabel,
    );
    final dest = _branchDisplay(
      name: detail.destinationSectorName,
      id: detail.destinationSectorId,
      branchLabel: branchLabel,
    );
    String? weight;
    final map = OutboundDataParse.asStringKeyedMap(rawData);
    if (map != null) {
      weight = OutboundDataParse.firstNonEmptyString(map, const [
        'gross_weight',
        'bag_weight',
        'total_weight',
      ]);
    }
    return ManifestBagSessionRow(
      bagCode: code,
      originLabel: origin,
      destinationLabel: dest,
      detail: detail,
      weight: weight,
    );
  }

  static String _branchDisplay({
    required String? name,
    required String? id,
    required String Function(String? id) branchLabel,
  }) {
    final n = name?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (id != null && id.trim().isNotEmpty) return branchLabel(id.trim());
    return '—';
  }
}

/// One shipment line aggregated from session bag `items[]`.
class ManifestShipmentSessionRow {
  const ManifestShipmentSessionRow({
    required this.bagNumber,
    this.boxNo,
    this.consignmentNo,
    this.origin,
    this.consigneeCode,
    this.consigneeName,
    this.cityName,
    this.pcs,
    this.description,
    this.invVal,
    this.grossWeight,
    this.volumetricWeight,
  });

  final String bagNumber;
  final String? boxNo;
  final String? consignmentNo;
  final String? origin;
  final String? consigneeCode;
  final String? consigneeName;
  final String? cityName;
  final String? pcs;
  final String? description;
  final String? invVal;
  final String? grossWeight;
  final String? volumetricWeight;

  String get sessionKey =>
      '$bagNumber|${consignmentNo ?? ''}|${boxNo ?? ''}'.trim();

  factory ManifestShipmentSessionRow.fromBagDetailItem(
    BagDetailItem item, {
    required String bagCode,
    String? originLabel,
    Map<String, dynamic>? rawJson,
  }) {
    final json = rawJson ?? const <String, dynamic>{};
    return ManifestShipmentSessionRow(
      bagNumber: bagCode,
      boxNo: OutboundDataParse.firstNonEmptyString(json, const [
            'box_no',
            'box_number',
          ]) ??
          item.boxNo ??
          item.shipmentInvoiceNo,
      consignmentNo: item.shipmentId,
      origin: originLabel,
      consigneeCode: OutboundDataParse.firstNonEmptyString(json, const [
        'consignee_code',
        'client_code',
        'receiver_code',
      ]),
      consigneeName: OutboundDataParse.firstNonEmptyString(json, const [
        'consignee_name',
        'receiver_name',
      ]),
      cityName: OutboundDataParse.optionalString(json, 'destination_city'),
      pcs: OutboundDataParse.firstNonEmptyString(json, const [
            'number_of_parcel',
            'no_of_package',
            'pcs',
          ]) ??
          item.shipmentInvoiceNo ??
          '1',
      description: OutboundDataParse.firstNonEmptyString(json, const [
            'description',
            'goods_description',
          ]) ??
          item.shipmentStatus,
      invVal: OutboundDataParse.firstNonEmptyString(json, const [
        'invoice_value',
        'inv_val',
        'actual_value',
      ]),
      grossWeight: OutboundDataParse.optionalString(json, 'gross_weight'),
      volumetricWeight: OutboundDataParse.optionalString(json, 'volumetric_weight'),
    );
  }
}
