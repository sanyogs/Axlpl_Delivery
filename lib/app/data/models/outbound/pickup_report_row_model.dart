import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Row from `pickupreport` GET — `[{status, count}, …]`.
class PickupReportRow {
  const PickupReportRow({this.status, this.count});

  final String? status;
  final String? count;

  factory PickupReportRow.fromJson(Map<String, dynamic> json) {
    return PickupReportRow(
      status: OutboundDataParse.optionalString(json, 'status'),
      count: OutboundDataParse.optionalString(json, 'count'),
    );
  }

  static List<PickupReportRow> listFromDynamic(dynamic data) =>
      OutboundDataParse.mapListFromDynamic(data, PickupReportRow.fromJson);
}
