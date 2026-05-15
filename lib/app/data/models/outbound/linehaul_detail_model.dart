import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Inner `data` from `getlinehauldetails` after [ApiClient] unwrap.
class LinehaulDetail {
  const LinehaulDetail(this.inner);

  final dynamic inner;

  factory LinehaulDetail.fromDynamic(dynamic data) => LinehaulDetail(data);

  Map<String, dynamic>? get asMap => OutboundDataParse.asStringKeyedMap(inner);

  String? get linehaulId => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['linehaul_id', 'id', 'linehaulId'],
      );

  String? get vehicleNo => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['vehicle_no', 'vehicleNo', 'vehicle'],
      );

  String? get driverName => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['driver_name', 'driverName', 'driver'],
      );

  String? get status =>
      OutboundDataParse.firstNonEmptyString(asMap, const ['status']);

  String? get manifestIds => OutboundDataParse.firstNonEmptyString(
        asMap,
        const ['manifest_ids', 'manifestIds', 'manifest_id'],
      );

  dynamic get rawForDisplay => inner;

  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) lines.add('$label: $value');
    }
    add('Linehaul id', linehaulId);
    add('Vehicle', vehicleNo);
    add('Driver', driverName);
    add('Status', status);
    add('Manifest ids', manifestIds);
    return lines;
  }
}
