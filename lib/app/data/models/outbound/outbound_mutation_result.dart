import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Parsed inner `data` from outbound POST success payloads (create bag, manifest, etc.).
class OutboundMutationResult {
  const OutboundMutationResult(this.inner);

  final dynamic inner;

  factory OutboundMutationResult.fromDynamic(dynamic data) =>
      OutboundMutationResult(data);

  Map<String, dynamic>? get asMap => OutboundDataParse.asStringKeyedMap(inner);

  String? get bagId =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['bag_id', 'id', 'bagId']);

  String? get bagCode =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['bag_code', 'bagCode', 'code']);

  /// Prefer numeric id; fall back to bag code when server returns id 0.
  String? get effectiveBagRef {
    if (bagId != null && bagId!.isNotEmpty && bagId != '0') return bagId;
    return bagCode;
  }

  String? get manifestId => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['manifest_id', 'id', 'manifestId'],
      );

  String? get linehaulId => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['linehaul_id', 'id', 'linehaulId'],
      );

  String? get tripNo =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['trip_no', 'tripNo']);

  String? get effectiveLinehaulRef {
    if (linehaulId != null && linehaulId!.isNotEmpty && linehaulId != '0') {
      return linehaulId;
    }
    return tripNo;
  }

  int? get bagIdInt => int.tryParse(bagId ?? '');

  /// Server has returned `success` with `bag_id: 0` for invalid input (known quirk).
  bool get hasInvalidBagId {
    final id = bagIdInt;
    return id != null && id <= 0;
  }

  dynamic get rawForDisplay => inner;
}
