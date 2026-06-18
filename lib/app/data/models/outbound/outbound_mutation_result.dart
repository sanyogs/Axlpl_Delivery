import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';

/// Parsed inner `data` from outbound POST success payloads (create bag, manifest, etc.).
class OutboundMutationResult {
  const OutboundMutationResult({
    this.bagId,
    this.bagCode,
    this.metalSealNo,
    this.shipmentsCount,
    this.manifestId,
    this.manifestNo,
    this.linehaulId,
    this.tripNo,
    this.raw,
  });

  final String? bagId;
  final String? bagCode;
  final String? metalSealNo;
  final int? shipmentsCount;
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
      metalSealNo: OutboundDataParse.firstNonEmptyString(json, const [
        'metal_seal_no',
        'metalSealNo',
      ]),
      shipmentsCount: OutboundDataParse.optionalInt(json, 'shipments_count'),
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
    if (map == null) return OutboundMutationResult(raw: data);
    final nested = OutboundDataParse.asStringKeyedMap(map['data']);
    if (nested != null &&
        (nested.containsKey('linehaul_id') ||
            nested.containsKey('trip_no') ||
            nested.containsKey('bag_id') ||
            nested.containsKey('manifest_id'))) {
      return OutboundMutationResult.fromJson(nested);
    }
    return OutboundMutationResult.fromJson(map);
  }

  Map<String, dynamic>? get asMap => OutboundDataParse.asStringKeyedMap(raw);

  /// Prefer numeric id; fall back to bag code when server returns id 0.
  String? get effectiveBagRef {
    if (bagId != null && bagId!.isNotEmpty && bagId != '0') return bagId;
    return bagCode;
  }

  String? get effectiveLinehaulRef {
    final trip = tripNo?.trim();
    if (trip != null && trip.isNotEmpty && OutboundApiParams.looksLikeTripNo(trip)) {
      return trip;
    }
    if (linehaulId != null && linehaulId!.isNotEmpty && linehaulId != '0') {
      return linehaulId;
    }
    return tripNo;
  }

  /// Numeric `linehaul_id` from assign/create responses — required for `editlinehaul`.
  String? get numericLinehaulIdForEdit {
    final id = linehaulId?.trim();
    if (id == null || id.isEmpty || id == '0') return null;
    if (OutboundApiParams.looksLikeTripNo(id)) return null;
    return id;
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
