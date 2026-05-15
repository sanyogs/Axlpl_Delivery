import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

class ShipmentScanEvent {
  const ShipmentScanEvent({
    this.id,
    this.shipmentId,
    this.status,
    this.branchId,
    this.createdDate,
    this.modifiedDate,
    this.remark,
    this.receiverName,
  });

  final String? id;
  final String? shipmentId;
  final String? status;
  final String? branchId;
  final String? createdDate;
  final String? modifiedDate;
  final String? remark;
  final String? receiverName;

  factory ShipmentScanEvent.fromJson(Map<String, dynamic> json) {
    return ShipmentScanEvent(
      id: json['id']?.toString(),
      shipmentId: json['s_id']?.toString(),
      status: json['status']?.toString(),
      branchId: json['branch_id']?.toString(),
      createdDate: json['created_date']?.toString(),
      modifiedDate: json['modified_date']?.toString(),
      remark: json['remark']?.toString(),
      receiverName: json['receiver_name']?.toString(),
    );
  }

  static List<ShipmentScanEvent> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, ShipmentScanEvent.fromJson);
}
