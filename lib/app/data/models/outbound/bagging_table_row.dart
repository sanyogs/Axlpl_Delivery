import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';

/// One row in **Scanned Box Details** (staging before save or from `getbagdetails`).
class BaggingTableRow {
  const BaggingTableRow({
    this.bagCode,
    this.boxNumber,
    this.shipmentId,
    this.destination,
    this.mode,
    this.saved = false,
  });

  final String? bagCode;
  final String? boxNumber;
  final String? shipmentId;
  final String? destination;
  final String? mode;
  final bool saved;

  String get sessionKey {
    final id = shipmentId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return '';
  }

  /// Value for `docket_no` on `addshipmenttobag` / `removeshipmentfrombag` (Postman).
  String get docketForApi => sessionKey;

  BaggingTableRow copyWith({String? bagCode, bool? saved}) {
    return BaggingTableRow(
      bagCode: bagCode ?? this.bagCode,
      boxNumber: boxNumber,
      shipmentId: shipmentId,
      destination: destination,
      mode: mode,
      saved: saved ?? this.saved,
    );
  }

  factory BaggingTableRow.fromFetchedShipment({
    required HubScanFetchedShipment shipment,
    required String scanTyped,
    String? bagCode,
    String? destination,
    bool saved = false,
  }) {
    final id = shipment.connoteForScan.isNotEmpty
        ? shipment.connoteForScan
        : scanTyped.trim();
    return BaggingTableRow(
      bagCode: bagCode,
      boxNumber: shipment.numberOfParcel ?? shipment.scannedCount ?? '1',
      shipmentId: id,
      destination: destination ??
          shipment.destinationCity ??
          shipment.destinationPincode,
      mode: null,
      saved: saved,
    );
  }

  factory BaggingTableRow.fromBagDetailItem(
    BagDetailItem item, {
    String? bagCode,
    String? destination,
    String? mode,
  }) {
    return BaggingTableRow(
      bagCode: bagCode,
      boxNumber: item.boxNo ?? item.shipmentInvoiceNo ?? '1',
      shipmentId: item.shipmentId,
      destination: destination,
      mode: mode ?? item.shipmentStatus ?? '—',
      saved: true,
    );
  }
}
