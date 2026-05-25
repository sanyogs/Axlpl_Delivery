import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

class SectorPickupRow {
  const SectorPickupRow({
    this.id,
    this.mawbNo,
    this.hubId,
    this.pickedBy,
    this.pickupDate,
    this.pickupTime,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? mawbNo;
  final String? hubId;
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
