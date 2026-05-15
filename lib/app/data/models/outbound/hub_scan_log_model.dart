import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

class HubScanLog {
  const HubScanLog({
    this.id,
    this.shipmentId,
    this.scanType,
    this.branchId,
    this.scannedAt,
    this.createdAt,
    this.updatedAt,
    this.boxNo,
    this.shipmentInvoiceNo,
  });

  final String? id;
  final String? shipmentId;
  final String? scanType;
  final String? branchId;
  final String? scannedAt;
  final String? createdAt;
  final String? updatedAt;
  final String? boxNo;
  final String? shipmentInvoiceNo;

  factory HubScanLog.fromJson(Map<String, dynamic> json) {
    return HubScanLog(
      id: json['id']?.toString(),
      shipmentId: json['shipment_id']?.toString(),
      scanType: json['scan_type']?.toString(),
      branchId: json['branch_id']?.toString(),
      scannedAt: json['scanned_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      boxNo: json['box_no']?.toString(),
      shipmentInvoiceNo: json['shipment_invoice_no']?.toString(),
    );
  }

  static List<HubScanLog> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, HubScanLog.fromJson);
}
