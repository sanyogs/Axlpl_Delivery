import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Shipment row inside manifest detail/report `shipments[]`.
class ManifestShipmentRef {
  const ManifestShipmentRef({
    this.id,
    this.shipmentInvoiceNo,
    this.shipmentStatus,
    this.bagId,
    this.bagCode,
    this.senderName,
    this.receiverName,
    this.destinationCity,
    this.numberOfParcel,
    this.grossWeight,
    this.volumetricWeight,
  });

  final String? id;
  final String? shipmentInvoiceNo;
  final String? shipmentStatus;
  final String? bagId;
  final String? bagCode;
  final String? senderName;
  final String? receiverName;
  final String? destinationCity;
  final String? numberOfParcel;
  final String? grossWeight;
  final String? volumetricWeight;

  factory ManifestShipmentRef.fromJson(Map<String, dynamic> json) {
    return ManifestShipmentRef(
      id: OutboundDataParse.optionalString(json, 'id'),
      shipmentInvoiceNo:
          OutboundDataParse.optionalString(json, 'shipment_invoice_no'),
      shipmentStatus: OutboundDataParse.optionalString(json, 'shipment_status'),
      bagId: OutboundDataParse.optionalString(json, 'bag_id'),
      bagCode: OutboundDataParse.optionalString(json, 'bag_code'),
      senderName: OutboundDataParse.optionalString(json, 'sender_name'),
      receiverName: OutboundDataParse.optionalString(json, 'receiver_name'),
      destinationCity: OutboundDataParse.optionalString(json, 'destination_city'),
      numberOfParcel: OutboundDataParse.firstNonEmptyString(json, const [
        'number_of_parcel',
        'no_of_package',
      ]),
      grossWeight: OutboundDataParse.firstNonEmptyString(json, const [
        'gross_weight',
        'total_weight',
        'weight',
      ]),
      volumetricWeight: OutboundDataParse.firstNonEmptyString(json, const [
        'volumetric_weight',
        'vol_weight',
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (shipmentInvoiceNo != null) 'shipment_invoice_no': shipmentInvoiceNo,
        if (shipmentStatus != null) 'shipment_status': shipmentStatus,
        if (bagId != null) 'bag_id': bagId,
        if (bagCode != null) 'bag_code': bagCode,
        if (senderName != null) 'sender_name': senderName,
        if (receiverName != null) 'receiver_name': receiverName,
        if (destinationCity != null) 'destination_city': destinationCity,
        if (numberOfParcel != null) 'number_of_parcel': numberOfParcel,
        if (grossWeight != null) 'gross_weight': grossWeight,
        if (volumetricWeight != null) 'volumetric_weight': volumetricWeight,
      };

  static List<ManifestShipmentRef> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, ManifestShipmentRef.fromJson);
}
