import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `listbags` (raw JSON array).
class OutboundBagRow {
  const OutboundBagRow({
    this.id,
    this.bagCode,
    this.metalSealNo,
    this.originBranchId,
    this.destinationSectorId,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? bagCode;
  final String? metalSealNo;
  final String? originBranchId;
  final String? destinationSectorId;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  String? get bagId => id;

  String? get destinationBranchId => destinationSectorId;

  String? get status => null;

  factory OutboundBagRow.fromJson(Map<String, dynamic> json) {
    return OutboundBagRow(
      id: OutboundDataParse.optionalString(json, 'id'),
      bagCode: OutboundDataParse.firstNonEmptyString(json, const [
        'bag_code',
        'code',
        'bagCode',
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
        'destination_branch',
      ]),
      createdBy: OutboundDataParse.optionalString(json, 'created_by'),
      createdAt: OutboundDataParse.firstNonEmptyString(json, const [
        'created_at',
        'createdAt',
      ]),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
    );
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
      };

  Map<String, dynamic> get asMap => toJson();

  static List<OutboundBagRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, OutboundBagRow.fromJson);
}
