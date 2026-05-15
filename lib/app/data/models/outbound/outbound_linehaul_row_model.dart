import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `listlinehauls` inner `data`.
class OutboundLinehaulRow {
  const OutboundLinehaulRow(this.raw);

  final Map<String, dynamic> raw;

  factory OutboundLinehaulRow.fromJson(Map<String, dynamic> json) =>
      OutboundLinehaulRow(json);

  String? get linehaulId => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['linehaul_id', 'id', 'linehaulId'],
      );

  String? get vehicleNo => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['vehicle_no', 'vehicleNo', 'vehicle'],
      );

  String? get driverName => OutboundDataParse.firstNonEmptyString(
        raw,
        const ['driver_name', 'driverName', 'driver'],
      );

  String? get status =>
      OutboundDataParse.firstNonEmptyString(raw, const ['status']);

  Map<String, dynamic> get asMap => raw;

  static List<OutboundLinehaulRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, OutboundLinehaulRow.fromJson);
}
