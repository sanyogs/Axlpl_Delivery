import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';

/// One row in **Scanned Box Details** (staging before save or from `getbagdetails`).
class BaggingTableRow {
  const BaggingTableRow({
    this.boxNumber,
    this.shipmentId,
    this.destination,
    this.mode,
    this.saved = false,
  });

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

  BaggingTableRow copyWith({bool? saved}) {
    return BaggingTableRow(
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
    String? destination,
    bool saved = false,
  }) {
    final id = shipment.connoteForScan.isNotEmpty
        ? shipment.connoteForScan
        : scanTyped.trim();
    return BaggingTableRow(
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
    String? destination,
  }) {
    return BaggingTableRow(
      boxNumber: item.boxNo ?? item.shipmentInvoiceNo ?? '1',
      shipmentId: item.shipmentId,
      destination: destination,
      mode: item.shipmentStatus ?? '—',
      saved: true,
    );
  }
}
