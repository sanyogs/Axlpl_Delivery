import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Parsed inner `data` from outbound POST success payloads (create bag, manifest, etc.).
class OutboundMutationResult {
  const OutboundMutationResult({
    this.bagId,
    this.bagCode,
    this.manifestId,
    this.manifestNo,
    this.linehaulId,
    this.tripNo,
    this.raw,
  });

  final String? bagId;
  final String? bagCode;
  final String? manifestId;
  final String? manifestNo;
  final String? linehaulId;
  final String? tripNo;
  final dynamic raw;

  factory OutboundMutationResult.fromJson(Map<String, dynamic> json) {
    return OutboundMutationResult(
      bagId: OutboundDataParse.firstNonEmptyString(json, const [
        'bag_id',
        'id',
        'bagId',
      ]),
      bagCode: OutboundDataParse.firstNonEmptyString(json, const [
        'bag_code',
        'bagCode',
        'code',
      ]),
      manifestId: OutboundDataParse.firstNonEmptyString(json, const [
        'manifest_id',
        'id',
        'manifestId',
      ]),
      manifestNo: OutboundDataParse.firstNonEmptyString(json, const [
        'manifest_no',
        'manifest_code',
        'manifestNo',
      ]),
      linehaulId: OutboundDataParse.firstNonEmptyString(json, const [
        'linehaul_id',
        'id',
        'linehaulId',
      ]),
      tripNo: OutboundDataParse.firstNonEmptyString(json, const [
        'trip_no',
        'tripNo',
      ]),
      raw: json,
    );
  }

  factory OutboundMutationResult.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return OutboundMutationResult.fromJson(map);
    return OutboundMutationResult(raw: data);
  }

  Map<String, dynamic>? get asMap => OutboundDataParse.asStringKeyedMap(raw);

  /// Prefer numeric id; fall back to bag code when server returns id 0.
  String? get effectiveBagRef {
    if (bagId != null && bagId!.isNotEmpty && bagId != '0') return bagId;
    return bagCode;
  }

  String? get effectiveLinehaulRef {
    if (linehaulId != null && linehaulId!.isNotEmpty && linehaulId != '0') {
      return linehaulId;
    }
    return tripNo;
  }

  /// Prefer manifest code (MUM094); fall back to numeric id.
  String? get effectiveManifestRef {
    if (manifestNo != null && manifestNo!.isNotEmpty) return manifestNo;
    if (manifestId != null && manifestId!.isNotEmpty && manifestId != '0') {
      return manifestId;
    }
    return null;
  }

  int? get bagIdInt => int.tryParse(bagId ?? '');

  /// Server has returned `success` with `bag_id: 0` for invalid input (known quirk).
  bool get hasInvalidBagId {
    final id = bagIdInt;
    return id != null && id <= 0;
  }

  dynamic get rawForDisplay => raw ?? asMap;
}
