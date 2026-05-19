import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `listlinehauls` (raw JSON array).
class OutboundLinehaulRow {
  const OutboundLinehaulRow({
    this.linehaulId,
    this.tripNo,
    this.vehicleNo,
    this.driverName,
    this.status,
  });

  final String? linehaulId;
  final String? tripNo;
  final String? vehicleNo;
  final String? driverName;
  final String? status;

  String? get effectiveRef {
    if (tripNo != null && tripNo!.isNotEmpty) return tripNo;
    if (linehaulId != null && linehaulId!.isNotEmpty && linehaulId != '0') {
      return linehaulId;
    }
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
    );
  }

  Map<String, dynamic> toJson() => {
        if (linehaulId != null) 'linehaul_id': linehaulId,
        if (tripNo != null) 'trip_no': tripNo,
        if (vehicleNo != null) 'vehicle_no': vehicleNo,
        if (driverName != null) 'driver_name': driverName,
        if (status != null) 'status': status,
      };

  Map<String, dynamic> get asMap => toJson();

  static List<OutboundLinehaulRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, OutboundLinehaulRow.fromJson);
}
