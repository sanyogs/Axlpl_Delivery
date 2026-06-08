import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

class SectorPickupRow {
  const SectorPickupRow({
    this.id,
    this.mawbNo,
    this.hubId,
    this.originHub,
    this.destHub,
    this.pickedBy,
    this.pickupDate,
    this.pickupTime,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? mawbNo;
  final String? hubId;
  final String? originHub;
  final String? destHub;
  final String? pickedBy;
  final String? pickupDate;
  final String? pickupTime;
  final String? createdAt;
  final String? updatedAt;

  factory SectorPickupRow.fromJson(Map<String, dynamic> json) {
    return SectorPickupRow(
      id: OutboundDataParse.firstNonEmptyString(json, ['id', 'pickup_id']),
      mawbNo: json['mawb_no']?.toString(),
      hubId: json['hub_id']?.toString(),
      originHub: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_hub',
        'origin_branch',
        'origin_branch_id',
        'origin_hub_id',
      ]),
      destHub: OutboundDataParse.firstNonEmptyString(json, const [
        'dest_hub',
        'destination_hub',
        'destination_branch',
        'destination_branch_id',
        'destination_sector_id',
      ]),
      pickedBy: json['picked_by']?.toString(),
      pickupDate: json['pickup_date']?.toString(),
      pickupTime: json['pickup_time']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  static List<SectorPickupRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, SectorPickupRow.fromJson);
}
