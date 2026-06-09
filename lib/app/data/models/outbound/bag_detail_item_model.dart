import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Shipment row inside `getbagdetails` → `items[]`.
class BagDetailItem {
  const BagDetailItem({
    this.id,
    this.bagId,
    this.shipmentId,
    this.createdAt,
    this.updatedAt,
    this.shipmentInvoiceNo,
    this.shipmentStatus,
    this.boxNo,
    this.senderName,
    this.receiverName,
    this.destinationCity,
    this.totalWeight,
    this.noOfPackage,
  });

  final String? id;
  final String? bagId;
  final String? shipmentId;
  final String? createdAt;
  final String? updatedAt;
  final String? shipmentInvoiceNo;
  final String? shipmentStatus;
  final String? boxNo;
  final String? senderName;
  final String? receiverName;
  final String? destinationCity;
  final String? totalWeight;
  final String? noOfPackage;

  factory BagDetailItem.fromJson(Map<String, dynamic> json) {
    return BagDetailItem(
      id: OutboundDataParse.optionalString(json, 'id'),
      bagId: OutboundDataParse.optionalString(json, 'bag_id'),
      shipmentId: OutboundDataParse.firstNonEmptyString(json, const [
        'shipment_id',
        'docket_no',
        's_id',
      ]),
      createdAt: OutboundDataParse.optionalString(json, 'created_at'),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
      shipmentInvoiceNo:
          OutboundDataParse.optionalString(json, 'shipment_invoice_no'),
      shipmentStatus: OutboundDataParse.optionalString(json, 'shipment_status'),
      boxNo: OutboundDataParse.firstNonEmptyString(json, const [
        'box_no',
        'box_number',
        'boxNumber',
      ]),
      senderName: OutboundDataParse.optionalString(json, 'sender_name'),
      receiverName: OutboundDataParse.optionalString(json, 'receiver_name'),
      destinationCity: OutboundDataParse.optionalString(json, 'destination_city'),
      totalWeight: OutboundDataParse.firstNonEmptyString(json, const [
        'total_weight',
        'gross_weight',
      ]),
      noOfPackage: OutboundDataParse.firstNonEmptyString(json, const [
        'no_of_package',
        'number_of_parcel',
        'pcs',
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (bagId != null) 'bag_id': bagId,
        if (shipmentId != null) 'shipment_id': shipmentId,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        if (shipmentInvoiceNo != null) 'shipment_invoice_no': shipmentInvoiceNo,
        if (shipmentStatus != null) 'shipment_status': shipmentStatus,
      };

  static List<BagDetailItem> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, BagDetailItem.fromJson);
}
