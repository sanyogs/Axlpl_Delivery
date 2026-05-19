import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Shipment row inside `baggingreport` → `items[]`.
class BaggingReportItem {
  const BaggingReportItem({
    this.shipmentId,
    this.shipmentInvoiceNo,
    this.senderName,
    this.receiverName,
    this.destinationCity,
    this.totalWeight,
    this.noOfPackage,
  });

  final String? shipmentId;
  final String? shipmentInvoiceNo;
  final String? senderName;
  final String? receiverName;
  final String? destinationCity;
  final String? totalWeight;
  final String? noOfPackage;

  factory BaggingReportItem.fromJson(Map<String, dynamic> json) {
    return BaggingReportItem(
      shipmentId: OutboundDataParse.firstNonEmptyString(json, const [
        'shipment_id',
        'docket_no',
        's_id',
      ]),
      shipmentInvoiceNo:
          OutboundDataParse.optionalString(json, 'shipment_invoice_no'),
      senderName: OutboundDataParse.optionalString(json, 'sender_name'),
      receiverName: OutboundDataParse.optionalString(json, 'receiver_name'),
      destinationCity: OutboundDataParse.optionalString(json, 'destination_city'),
      totalWeight: OutboundDataParse.optionalString(json, 'total_weight'),
      noOfPackage: OutboundDataParse.optionalString(json, 'no_of_package'),
    );
  }

  Map<String, dynamic> toJson() => {
        if (shipmentId != null) 'shipment_id': shipmentId,
        if (shipmentInvoiceNo != null) 'shipment_invoice_no': shipmentInvoiceNo,
        if (senderName != null) 'sender_name': senderName,
        if (receiverName != null) 'receiver_name': receiverName,
        if (destinationCity != null) 'destination_city': destinationCity,
        if (totalWeight != null) 'total_weight': totalWeight,
        if (noOfPackage != null) 'no_of_package': noOfPackage,
      };

  static List<BaggingReportItem> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, BaggingReportItem.fromJson);
}
