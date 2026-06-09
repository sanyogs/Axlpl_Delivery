import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Response from `getpickupdetail`.
class PickupDetail {
  const PickupDetail({
    this.id,
    this.mawbNo,
    this.hubId,
    this.originHub,
    this.destinationHub,
    this.originBranch,
    this.destinationBranch,
    this.flightNo,
    this.pickupDate,
    this.pickupTime,
    this.pickedBy,
    this.totalShipments,
    this.shipmentList = const [],
  });

  final String? id;
  final String? mawbNo;
  final String? hubId;
  final String? originHub;
  final String? destinationHub;
  final String? originBranch;
  final String? destinationBranch;
  final String? flightNo;
  final String? pickupDate;
  final String? pickupTime;
  final String? pickedBy;
  final int? totalShipments;
  final List<PickupDetailShipment> shipmentList;

  factory PickupDetail.fromJson(Map<String, dynamic> json) {
    return PickupDetail(
      id: OutboundDataParse.firstNonEmptyString(json, const ['id', 'pickup_id']),
      mawbNo: OutboundDataParse.optionalString(json, 'mawb_no'),
      hubId: OutboundDataParse.optionalString(json, 'hub_id'),
      originHub: OutboundDataParse.optionalString(json, 'origin_hub'),
      destinationHub: OutboundDataParse.optionalString(json, 'destination_hub'),
      originBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch',
        'origin_branch_name',
      ]),
      destinationBranch: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_branch',
        'destination_branch_name',
      ]),
      flightNo: OutboundDataParse.optionalString(json, 'flight_no'),
      pickupDate: OutboundDataParse.optionalString(json, 'pickup_date'),
      pickupTime: OutboundDataParse.optionalString(json, 'pickup_time'),
      pickedBy: OutboundDataParse.optionalString(json, 'picked_by'),
      totalShipments: OutboundDataParse.optionalInt(json, 'total_shipments'),
      shipmentList: PickupDetailShipment.listFromDynamic(json['shipment_list']),
    );
  }

  factory PickupDetail.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return PickupDetail.fromJson(map);
    return const PickupDetail();
  }
}

class PickupDetailShipment {
  const PickupDetailShipment({
    this.shipmentId,
    this.shipmentInvoiceNo,
    this.status,
    this.senderName,
    this.receiverName,
  });

  final String? shipmentId;
  final String? shipmentInvoiceNo;
  final String? status;
  final String? senderName;
  final String? receiverName;

  factory PickupDetailShipment.fromJson(Map<String, dynamic> json) {
    return PickupDetailShipment(
      shipmentId: OutboundDataParse.firstNonEmptyString(json, const [
        'shipment_id',
        'docket_no',
      ]),
      shipmentInvoiceNo:
          OutboundDataParse.optionalString(json, 'shipment_invoice_no'),
      status: OutboundDataParse.optionalString(json, 'status'),
      senderName: OutboundDataParse.optionalString(json, 'sender_name'),
      receiverName: OutboundDataParse.optionalString(json, 'receiver_name'),
    );
  }

  static List<PickupDetailShipment> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, PickupDetailShipment.fromJson);
}
