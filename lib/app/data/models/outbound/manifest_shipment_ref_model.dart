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
    this.netWeight,
    this.volumetricWeight,
    this.paymentMode,
    this.productMode,
    this.entryNo,
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
  final String? netWeight;
  final String? volumetricWeight;
  final String? paymentMode;
  final String? productMode;
  final String? entryNo;

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
      netWeight: OutboundDataParse.firstNonEmptyString(json, const [
        'net_weight',
        'billing_weight',
        'chargeable_weight',
      ]),
      volumetricWeight: OutboundDataParse.firstNonEmptyString(json, const [
        'volumetric_weight',
        'vol_weight',
      ]),
      paymentMode: OutboundDataParse.firstNonEmptyString(json, const [
        'payment_mode',
        'paid',
        'payment_type',
        'shipment_type',
        'pay_mode',
      ]),
      productMode: OutboundDataParse.firstNonEmptyString(json, const [
        'product_mode',
        'mode',
        'product_type',
      ]),
      entryNo: OutboundDataParse.optionalString(json, 'entry_no'),
    );
  }

  String get docketNo => id?.trim().isNotEmpty == true
      ? id!.trim()
      : (shipmentInvoiceNo?.trim().isNotEmpty == true
          ? shipmentInvoiceNo!.trim()
          : '—');

  String get pcsDisplay {
    final pcs = numberOfParcel?.trim();
    if (pcs != null && pcs.isNotEmpty) return pcs;
    return '—';
  }

  String get netWeightDisplay {
    final net = netWeight?.trim();
    if (net != null && net.isNotEmpty) return net;
    return grossWeight?.trim().isNotEmpty == true ? grossWeight!.trim() : '—';
  }

  String get grossWeightDisplay =>
      grossWeight?.trim().isNotEmpty == true ? grossWeight!.trim() : '—';

  String get paidDisplay {
    final paid = paymentMode?.trim();
    if (paid != null && paid.isNotEmpty) return paid;
    final status = shipmentStatus?.trim();
    if (status != null && status.isNotEmpty) return status;
    return '—';
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
        if (netWeight != null) 'net_weight': netWeight,
        if (volumetricWeight != null) 'volumetric_weight': volumetricWeight,
        if (paymentMode != null) 'payment_mode': paymentMode,
        if (productMode != null) 'product_mode': productMode,
        if (entryNo != null) 'entry_no': entryNo,
      };

  static List<ManifestShipmentRef> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, ManifestShipmentRef.fromJson);
}
