import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Bag reference inside manifest detail/report `bags[]`.
class ManifestBagRef {
  const ManifestBagRef({
    this.id,
    this.bagCode,
    this.metalSealNo,
    this.grossWeight,
  });

  final String? id;
  final String? bagCode;
  final String? metalSealNo;
  final String? grossWeight;

  factory ManifestBagRef.fromJson(Map<String, dynamic> json) {
    return ManifestBagRef(
      id: OutboundDataParse.optionalString(json, 'id'),
      bagCode: OutboundDataParse.firstNonEmptyString(json, const [
        'bag_code',
        'code',
      ]),
      metalSealNo: OutboundDataParse.optionalString(json, 'metal_seal_no'),
      grossWeight: OutboundDataParse.optionalString(json, 'gross_weight'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (bagCode != null) 'bag_code': bagCode,
        if (metalSealNo != null) 'metal_seal_no': metalSealNo,
        if (grossWeight != null) 'gross_weight': grossWeight,
      };

  static List<ManifestBagRef> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, ManifestBagRef.fromJson);
}
