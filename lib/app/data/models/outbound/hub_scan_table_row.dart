import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';

/// One scanned docket — snapshot of the form above (staging before Save).
class HubScanTableRow {
  const HubScanTableRow({
    this.docketNo,
    this.shipmentId,
    this.receiver,
    this.clientCode,
    this.noOfBox,
    this.boxWeight,
    this.originPincode,
    this.destPincode,
    this.destCity,
    this.actualWeight,
    this.value,
    this.scanType,
    this.branchId,
    this.saved = false,
  });

  final String? docketNo;
  final String? shipmentId;
  final String? receiver;
  final String? clientCode;
  final String? noOfBox;
  final String? boxWeight;
  final String? originPincode;
  final String? destPincode;
  final String? destCity;
  final String? actualWeight;
  final String? value;
  final String? scanType;
  final String? branchId;
  final bool saved;

  String get sessionKey {
    final id = shipmentId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return docketNo?.trim() ?? '';
  }

  HubScanTableRow copyWith({bool? saved}) {
    return HubScanTableRow(
      docketNo: docketNo,
      shipmentId: shipmentId,
      receiver: receiver,
      clientCode: clientCode,
      noOfBox: noOfBox,
      boxWeight: boxWeight,
      originPincode: originPincode,
      destPincode: destPincode,
      destCity: destCity,
      actualWeight: actualWeight,
      value: value,
      scanType: scanType,
      branchId: branchId,
      saved: saved ?? this.saved,
    );
  }

  /// Captures everything visible in the docket scan form after fetch.
  factory HubScanTableRow.fromFormSnapshot({
    required HubScanFetchedShipment shipment,
    required String scanDocketTyped,
    required String scanType,
    required String branchId,
    bool saved = false,
  }) {
    final docket = shipment.docketNo?.trim().isNotEmpty == true
        ? shipment.docketNo!
        : scanDocketTyped.trim();
    return HubScanTableRow(
      docketNo: docket,
      shipmentId: shipment.connoteForScan,
      receiver: shipment.receiverName,
      clientCode: shipment.clientCode,
      noOfBox: shipment.numberOfParcel,
      boxWeight: shipment.actualValue,
      originPincode: shipment.originPincode,
      destPincode: shipment.destinationPincode,
      destCity: shipment.destinationCity,
      actualWeight: shipment.actualValue,
      value: shipment.actualValue,
      scanType: scanType,
      branchId: branchId,
      saved: saved,
    );
  }
}
