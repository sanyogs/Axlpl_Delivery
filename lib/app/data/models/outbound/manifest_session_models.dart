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
    String? scannedBagCode,
  }) {
    final code = detail.bagCode?.trim().isNotEmpty == true
        ? detail.bagCode!.trim()
        : (scannedBagCode?.trim() ?? '');
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
    String? weight = detail.grossWeight?.trim();
    if (weight == null || weight.isEmpty) {
      final map = OutboundDataParse.asStringKeyedMap(rawData);
      if (map != null) {
        for (final level in _nestedMaps(map)) {
          weight = OutboundDataParse.firstNonEmptyString(level, const [
            'gross_weight',
            'bag_weight',
            'total_weight',
          ]);
          if (weight != null) break;
          final bag = OutboundDataParse.asStringKeyedMap(level['bag']);
          if (bag != null) {
            weight = OutboundDataParse.firstNonEmptyString(bag, const [
              'gross_weight',
              'bag_weight',
              'total_weight',
            ]);
            if (weight != null) break;
          }
        }
      }
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

  static List<Map<String, dynamic>> _nestedMaps(Map<String, dynamic> root) {
    final levels = <Map<String, dynamic>>[root];
    final data = OutboundDataParse.asStringKeyedMap(root['data']);
    if (data != null) {
      levels.add(data);
      final inner = OutboundDataParse.asStringKeyedMap(data['data']);
      if (inner != null) levels.add(inner);
    }
    return levels;
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
    String? originBranchName,
    Map<String, dynamic>? rawJson,
  }) {
    final json = rawJson ?? const <String, dynamic>{};
    final parcelCount = item.noOfPackage ??
        OutboundDataParse.firstNonEmptyString(json, const [
          'number_of_parcel',
          'no_of_package',
          'pcs',
        ]);

    return ManifestShipmentSessionRow(
      bagNumber: bagCode,
      boxNo: parcelCount,
      consignmentNo: item.shipmentId ??
          OutboundDataParse.firstNonEmptyString(json, const [
            'shipment_id',
            'docket_no',
          ]),
      origin: originBranchName,
      consigneeCode: item.consigneeCode ??
          OutboundDataParse.optionalString(json, 'consignee_code'),
      consigneeName: item.receiverName ??
          OutboundDataParse.optionalString(json, 'receiver_name'),
      cityName: item.destinationCity ??
          OutboundDataParse.optionalString(json, 'city_name'),
      pcs: parcelCount,
      description: OutboundDataParse.firstNonEmptyString(json, const [
        'description',
        'goods_description',
      ]),
      invVal: item.invoiceVal ??
          OutboundDataParse.firstNonEmptyString(json, const [
            'invoice_val',
            'invoice_value',
            'inv_val',
          ]),
      grossWeight: item.totalWeight ??
          OutboundDataParse.firstNonEmptyString(json, const [
            'gross_weight',
            'total_weight',
          ]),
      volumetricWeight: item.volumetricWeight ??
          OutboundDataParse.firstNonEmptyString(json, const [
            'volumetric_weight',
            'vol_weight',
          ]),
    );
  }
}
