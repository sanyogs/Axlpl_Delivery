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
      destinationCity: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_city',
        'city_name',
      ]),
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

extension BaggingReportItemTotals on BaggingReportItem {
  double get weightValue => double.tryParse(totalWeight?.trim() ?? '') ?? 0;

  int get pcsValue => int.tryParse(noOfPackage?.trim() ?? '') ?? 0;

  String get weightDisplay {
    final w = totalWeight?.trim();
    if (w != null && w.isNotEmpty) return w;
    return weightValue == weightValue.roundToDouble()
        ? weightValue.toStringAsFixed(0)
        : weightValue.toStringAsFixed(2);
  }

  String get pcsDisplay {
    final p = noOfPackage?.trim();
    if (p != null && p.isNotEmpty) return p;
    return pcsValue > 0 ? '$pcsValue' : '0';
  }
}
