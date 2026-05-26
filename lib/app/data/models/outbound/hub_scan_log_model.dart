import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';
import 'package:intl/intl.dart';

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

  /// Primary docket / invoice shown in list (admin: shipment id / docket column).
  String get docketDisplay {
    final invoice = shipmentInvoiceNo?.trim();
    if (invoice != null && invoice.isNotEmpty) return invoice;
    final sid = shipmentId?.trim();
    if (sid != null && sid.isNotEmpty) return sid;
    return '—';
  }

  String scanTypeDisplay(String? uiFallback) {
    final t = scanType?.trim();
    if (t == null || t.isEmpty) {
      final fb = uiFallback?.trim();
      return (fb != null && fb.isNotEmpty) ? fb : '—';
    }
    final u = t.toUpperCase();
    if (u == 'IN' || u == 'HUB IN') return 'HUB IN';
    if (u == 'OUT' || u == 'HUB OUT') return 'HUB OUT';
    return t;
  }

  static String branchDisplay(
    String? branchId,
    String Function(String? id) branchLabel,
  ) {
    if (branchId == null || branchId.trim().isEmpty) return '—';
    final key = branchId.trim();
    final lbl = branchLabel(key);
    if (lbl != '—' && lbl != key) return lbl;
    return 'Branch #$key';
  }

  static String formatDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final s = raw.trim();
    try {
      final normalized = s.contains('T') ? s : s.replaceFirst(' ', 'T');
      final dt = DateTime.parse(normalized);
      return DateFormat('dd-MMM-yyyy hh:mm a').format(dt.toLocal());
    } catch (_) {
      return s;
    }
  }

  String get scannedAtDisplay => formatDateTime(scannedAt);
  String get createdAtDisplay => formatDateTime(createdAt);
  String get updatedAtDisplay => formatDateTime(updatedAt);
}
