import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `listlinehauls` (raw JSON array).
class OutboundLinehaulRow {
  const OutboundLinehaulRow({
    this.linehaulId,
    this.tripNo,
    this.vehicleNo,
    this.driverName,
    this.status,
    this.origin,
    this.destination,
    this.transportType,
    this.bookingDate,
    this.mawbNo,
    this.ewayBill,
  });

  final String? linehaulId;
  final String? tripNo;
  final String? vehicleNo;
  final String? driverName;
  final String? status;
  final String? origin;
  final String? destination;
  final String? transportType;
  final String? bookingDate;
  final String? mawbNo;
  final String? ewayBill;

  String get displayMawbOrVehicle {
    final mawb = mawbNo?.trim();
    if (mawb != null && mawb.isNotEmpty) return mawb;
    final vehicle = vehicleNo?.trim();
    if (vehicle != null && vehicle.isNotEmpty) return vehicle;
    final trip = tripNo?.trim();
    if (trip != null && trip.isNotEmpty) return trip;
    return '—';
  }

  /// Prefer `mawb_no` then `linehaul_id` for `getlinehauldetails` (`trip_no` fails on API).
  String? get detailLookupRef {
    final mawb = mawbNo?.trim();
    if (mawb != null && mawb.isNotEmpty) return mawb;
    if (linehaulId != null && linehaulId!.isNotEmpty && linehaulId != '0') {
      return linehaulId;
    }
    final trip = tripNo?.trim();
    if (trip != null && trip.isNotEmpty) return trip;
    return null;
  }

  String? get effectiveRef => detailLookupRef;

  String? get deleteRef {
    final id = linehaulId?.trim();
    if (id != null && id.isNotEmpty && id != '0') return id;
    final trip = tripNo?.trim();
    if (trip != null && trip.isNotEmpty) return trip;
    final mawb = mawbNo?.trim();
    if (mawb != null && mawb.isNotEmpty) return mawb;
    return null;
  }

  factory OutboundLinehaulRow.fromJson(Map<String, dynamic> json) {
    return OutboundLinehaulRow(
      linehaulId: OutboundDataParse.firstNonEmptyString(json, const [
        'linehaul_id',
        'id',
        'linehaulId',
      ]),
      tripNo: OutboundDataParse.firstNonEmptyString(json, const [
        'trip_no',
        'tripNo',
      ]),
      vehicleNo: OutboundDataParse.firstNonEmptyString(json, const [
        'vehicle_no',
        'vehicleNo',
        'vehicle',
      ]),
      driverName: OutboundDataParse.firstNonEmptyString(json, const [
        'driver_name',
        'driverName',
        'driver',
      ]),
      status: OutboundDataParse.optionalString(json, 'status'),
      origin: OutboundDataParse.firstNonEmptyString(json, const [
        'origin',
        'origin_branch',
        'origin_branch_id',
        'origin_hub',
      ]),
      destination: OutboundDataParse.firstNonEmptyString(json, const [
        'destination',
        'destination_branch',
        'destination_branch_id',
        'destination_hub',
        'destination_sector_id',
      ]),
      transportType: OutboundDataParse.firstNonEmptyString(json, const [
        'transport_type',
        'transport',
        'airline',
      ]),
      bookingDate: OutboundDataParse.firstNonEmptyString(json, const [
        'booking_date',
        'created_at',
        'departure_time',
      ]),
      mawbNo: OutboundDataParse.firstNonEmptyString(json, const [
        'mawb_no',
        'airway_bill_no',
      ]),
      ewayBill: OutboundDataParse.firstNonEmptyString(json, const [
        'eway_bill',
        'ewayBill',
        'ewb',
      ]),
    );
  }

  Map<String, dynamic> toJson() => {
        if (linehaulId != null) 'linehaul_id': linehaulId,
        if (tripNo != null) 'trip_no': tripNo,
        if (vehicleNo != null) 'vehicle_no': vehicleNo,
        if (driverName != null) 'driver_name': driverName,
        if (status != null) 'status': status,
        if (origin != null) 'origin': origin,
        if (destination != null) 'destination': destination,
        if (transportType != null) 'transport_type': transportType,
        if (bookingDate != null) 'booking_date': bookingDate,
        if (mawbNo != null) 'mawb_no': mawbNo,
        if (ewayBill != null) 'eway_bill': ewayBill,
      };

  Map<String, dynamic> get asMap => toJson();

  static List<OutboundLinehaulRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, OutboundLinehaulRow.fromJson);
}
