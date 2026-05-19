import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Raw object from `getlinehauldetails` GET.
class LinehaulDetail {
  const LinehaulDetail({
    this.linehaulId,
    this.tripNo,
    this.vehicleNo,
    this.driverName,
    this.status,
    this.manifestIds,
    this.manifestCodes,
  });

  final String? linehaulId;
  final String? tripNo;
  final String? vehicleNo;
  final String? driverName;
  final String? status;
  final String? manifestIds;
  final String? manifestCodes;

  factory LinehaulDetail.fromJson(Map<String, dynamic> json) {
    return LinehaulDetail(
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
      manifestIds: OutboundDataParse.optionalString(json, 'manifest_ids'),
      manifestCodes: OutboundDataParse.optionalString(json, 'manifest_codes'),
    );
  }

  factory LinehaulDetail.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return LinehaulDetail.fromJson(map);
    return const LinehaulDetail();
  }

  dynamic get rawForDisplay => toJson();

  Map<String, dynamic> toJson() => {
        if (linehaulId != null) 'linehaul_id': linehaulId,
        if (tripNo != null) 'trip_no': tripNo,
        if (vehicleNo != null) 'vehicle_no': vehicleNo,
        if (driverName != null) 'driver_name': driverName,
        if (status != null) 'status': status,
        if (manifestIds != null) 'manifest_ids': manifestIds,
        if (manifestCodes != null) 'manifest_codes': manifestCodes,
      };

  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) lines.add('$label: $value');
    }

    add('Trip no', tripNo);
    add('Linehaul id', linehaulId);
    add('Vehicle', vehicleNo);
    add('Driver', driverName);
    add('Status', status);
    add('Manifests', manifestCodes ?? manifestIds);
    return lines;
  }
}
