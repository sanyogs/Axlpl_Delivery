import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Paginated response from `pickupreport` (admin Sector Pickup Status Report).
class SectorPickupStatusReportPage {
  const SectorPickupStatusReportPage({
    this.total = 0,
    this.page = 1,
    this.limit = 50,
    this.totalPages = 1,
    this.pickupDone,
    this.pickupPending,
    this.rows = const [],
  });

  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final int? pickupDone;
  final int? pickupPending;
  final List<SectorPickupStatusReportRow> rows;

  factory SectorPickupStatusReportPage.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map == null) {
      final legacy = SectorPickupStatusReportRow.listFromDynamic(data);
      if (legacy.isEmpty) return const SectorPickupStatusReportPage();
      return SectorPickupStatusReportPage(
        total: legacy.length,
        rows: legacy,
      );
    }

    final nested = OutboundDataParse.asStringKeyedMap(map['data']);
    final rowsSource = nested ?? map;
    final rows = SectorPickupStatusReportRow.listFromDynamic(
      rowsSource['data'] ?? rowsSource['rows'] ?? rowsSource['list'],
    );

    final legacySummary = _legacySummaryFromList(
      rowsSource['data'] ?? rowsSource['rows'] ?? rowsSource['list'] ?? data,
    );
    if (rows.isEmpty && legacySummary != null) {
      return SectorPickupStatusReportPage(
        total: legacySummary.total,
        pickupDone: legacySummary.done,
        pickupPending: legacySummary.pending,
      );
    }

    if (rows.isEmpty &&
        map.containsKey('status') &&
        map.containsKey('count')) {
      return const SectorPickupStatusReportPage();
    }

    return SectorPickupStatusReportPage(
      total: OutboundDataParse.optionalInt(rowsSource, 'total') ??
          OutboundDataParse.optionalInt(map, 'total') ??
          rows.length,
      page: OutboundDataParse.optionalInt(rowsSource, 'page') ??
          OutboundDataParse.optionalInt(map, 'page') ??
          1,
      limit: OutboundDataParse.optionalInt(rowsSource, 'limit') ??
          OutboundDataParse.optionalInt(map, 'limit') ??
          50,
      totalPages: OutboundDataParse.optionalInt(rowsSource, 'total_pages') ??
          OutboundDataParse.optionalInt(map, 'total_pages') ??
          1,
      pickupDone: _optionalCount(rowsSource, map, const [
        'sector_pickup_done',
        'pickup_done',
        'done_count',
        'pickup_done_count',
      ]),
      pickupPending: _optionalCount(rowsSource, map, const [
        'sector_pickup_pending',
        'pickup_pending',
        'pending_count',
        'pickup_pending_count',
      ]),
      rows: rows,
    );
  }

  static int? _optionalCount(
    Map<String, dynamic>? primary,
    Map<String, dynamic> fallback,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (primary != null) {
        final nested = OutboundDataParse.optionalInt(primary, key);
        if (nested != null) return nested;
      }
      final v = OutboundDataParse.optionalInt(fallback, key);
      if (v != null) return v;
    }
    return null;
  }

  static _LegacySummary? _legacySummaryFromList(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    final first = OutboundDataParse.asStringKeyedMap(raw.first);
    if (first == null || !first.containsKey('count')) return null;
    if (first.containsKey('shipment_id') ||
        first.containsKey('shipment_no') ||
        first.containsKey('linehaul_no')) {
      return null;
    }
    var total = 0;
    int? done;
    int? pending;
    for (final item in raw) {
      final row = OutboundDataParse.asStringKeyedMap(item);
      if (row == null) continue;
      final count = OutboundDataParse.optionalInt(row, 'count') ?? 0;
      total += count;
      final status = row['status']?.toString().toLowerCase() ?? '';
      if (status.contains('picked') && !status.contains('not')) {
        done = (done ?? 0) + count;
      } else if (status.contains('miss') || status.contains('pending')) {
        pending = (pending ?? 0) + count;
      }
    }
    return _LegacySummary(total: total, done: done, pending: pending);
  }
}

class _LegacySummary {
  const _LegacySummary({required this.total, this.done, this.pending});
  final int total;
  final int? done;
  final int? pending;
}

class SectorPickupStatusReportRow {
  const SectorPickupStatusReportRow({
    this.shipmentId,
    this.shipmentNo,
    this.origin,
    this.destination,
    this.linehaulNo,
    this.linehaulDate,
    this.sectorPickupNo,
    this.pickupDate,
    this.currentStatus,
    this.sectorPickupStatus,
  });

  final String? shipmentId;
  final String? shipmentNo;
  final String? origin;
  final String? destination;
  final String? linehaulNo;
  final String? linehaulDate;
  final String? sectorPickupNo;
  final String? pickupDate;
  final String? currentStatus;
  final String? sectorPickupStatus;

  String get displayShipmentNo {
    final no = shipmentNo?.trim();
    if (no != null && no.isNotEmpty) return no;
    return shipmentId?.trim().isNotEmpty == true ? shipmentId!.trim() : '—';
  }

  String get pickupStatusShort {
    final status = sectorPickupStatus?.trim();
    if (status == null || status.isEmpty) return '—';
    final upper = status.toUpperCase();
    if (upper.contains('DONE')) return 'DONE';
    if (upper.contains('PENDING')) return 'PENDING';
    return status;
  }

  factory SectorPickupStatusReportRow.fromJson(Map<String, dynamic> json) {
    return SectorPickupStatusReportRow(
      shipmentId: OutboundDataParse.firstNonEmptyString(json, const [
        'shipment_id',
        'docket_no',
        'awb',
      ]),
      shipmentNo: OutboundDataParse.firstNonEmptyString(json, const [
        'shipment_no',
        'shipment_invoice_no',
      ]),
      origin: OutboundDataParse.firstNonEmptyString(json, const [
        'origin',
        'origin_branch',
        'origin_branch_name',
        'origin_hub',
      ]),
      destination: OutboundDataParse.firstNonEmptyString(json, const [
        'destination',
        'destination_branch',
        'destination_branch_name',
        'destination_hub',
        'destination_city',
      ]),
      linehaulNo: OutboundDataParse.firstNonEmptyString(json, const [
        'linehaul_no',
        'mawb_no',
        'awb_no',
      ]),
      linehaulDate: OutboundDataParse.firstNonEmptyString(json, const [
        'linehaul_date',
        'departure_time',
      ]),
      sectorPickupNo: OutboundDataParse.firstNonEmptyString(json, const [
        'sector_pickup_no',
        'pickup_id',
        'sector_pickup_id',
      ]),
      pickupDate: OutboundDataParse.optionalString(json, 'pickup_date'),
      currentStatus: OutboundDataParse.firstNonEmptyString(json, const [
        'current_status',
        'shipment_status',
        'status',
      ]),
      sectorPickupStatus: OutboundDataParse.firstNonEmptyString(json, const [
        'sector_pickup_status',
        'pickup_status',
      ]),
    );
  }

  static List<SectorPickupStatusReportRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(
        data,
        SectorPickupStatusReportRow.fromJson,
      );

  List<String> csvCells() => [
        displayShipmentNo,
        origin ?? '—',
        destination ?? '—',
        linehaulNo ?? '—',
        linehaulDate ?? '—',
        pickupStatusShort,
        pickupDate ?? '—',
        currentStatus ?? '—',
      ];
}
