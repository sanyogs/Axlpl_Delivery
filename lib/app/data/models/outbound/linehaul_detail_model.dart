import 'package:axlpl_delivery/app/data/models/outbound/linehaul_manifest_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Raw object from `getlinehauldetails` GET (Postman / QA verify).
class LinehaulDetail {
  const LinehaulDetail({
    this.linehaulId,
    this.tripNo,
    this.origin,
    this.destination,
    this.transportType,
    this.airline,
    this.flightNo,
    this.mawbNo,
    this.airwayBillNo,
    this.vehicleNo,
    this.driverName,
    this.driverMobile,
    this.ewayBill,
    this.remarks,
    this.status,
    this.noOfBoxes,
    this.noOfBags,
    this.totalWeight,
    this.totalBillingWeight,
    this.departureTime,
    this.arrivalTime,
    this.createdAt,
    this.updatedAt,
    this.manifestIds,
    this.manifestCodes,
    this.manifests = const [],
    this.originBranchName,
    this.destinationBranchName,
    this.flightDate,
    this.shipmentCount,
    this.shipments = const [],
    this.bags = const [],
  });

  final String? linehaulId;
  final String? tripNo;
  final String? origin;
  final String? destination;
  final String? transportType;
  final String? airline;
  final String? flightNo;
  final String? mawbNo;
  final String? airwayBillNo;
  final String? vehicleNo;
  final String? driverName;
  final String? driverMobile;
  final String? ewayBill;
  final String? remarks;
  final String? status;
  final String? noOfBoxes;
  final String? noOfBags;
  final String? totalWeight;
  final String? totalBillingWeight;
  final String? departureTime;
  final String? arrivalTime;
  final String? createdAt;
  final String? updatedAt;
  final String? manifestIds;
  final String? manifestCodes;
  final List<LinehaulManifestRef> manifests;
  final String? originBranchName;
  final String? destinationBranchName;
  final String? flightDate;
  final int? shipmentCount;
  final List<ManifestShipmentRef> shipments;
  final List<ManifestBagRef> bags;

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
        'mawb_no',
      ]),
      origin: OutboundDataParse.optionalString(json, 'origin'),
      destination: OutboundDataParse.optionalString(json, 'destination'),
      transportType: OutboundDataParse.optionalString(json, 'transport_type'),
      airline: OutboundDataParse.optionalString(json, 'airline'),
      flightNo: OutboundDataParse.firstNonEmptyString(json, const [
        'flight_no',
        'flightNo',
      ]),
      mawbNo: OutboundDataParse.optionalString(json, 'mawb_no'),
      airwayBillNo: OutboundDataParse.optionalString(json, 'airway_bill_no'),
      vehicleNo: OutboundDataParse.firstNonEmptyString(json, const [
        'vehicle_no',
        'vehicleNo',
      ]),
      driverName: OutboundDataParse.firstNonEmptyString(json, const [
        'driver_name',
        'driverName',
      ]),
      driverMobile: OutboundDataParse.firstNonEmptyString(json, const [
        'driver_mobile',
        'driverMobile',
      ]),
      ewayBill: OutboundDataParse.firstNonEmptyString(json, const [
        'eway_bill',
        'ewayBill',
      ]),
      remarks: OutboundDataParse.optionalString(json, 'remarks'),
      status: OutboundDataParse.optionalString(json, 'status'),
      noOfBoxes: OutboundDataParse.optionalString(json, 'no_of_boxes'),
      noOfBags: OutboundDataParse.optionalString(json, 'no_of_bags'),
      totalWeight: OutboundDataParse.optionalString(json, 'total_weight'),
      totalBillingWeight:
          OutboundDataParse.optionalString(json, 'total_billing_weight'),
      departureTime: OutboundDataParse.optionalString(json, 'departure_time'),
      arrivalTime: OutboundDataParse.optionalString(json, 'arrival_time'),
      createdAt: OutboundDataParse.optionalString(json, 'created_at'),
      updatedAt: OutboundDataParse.optionalString(json, 'updated_at'),
      manifestIds: OutboundDataParse.optionalString(json, 'manifest_ids'),
      manifestCodes: OutboundDataParse.optionalString(json, 'manifest_codes'),
      manifests: LinehaulManifestRef.listFromDynamic(json['manifests']),
      originBranchName: OutboundDataParse.firstNonEmptyString(json, const [
        'origin_branch_name',
        'origin_hub',
        'origin_name',
        'origin_hub_name',
      ]),
      destinationBranchName: OutboundDataParse.firstNonEmptyString(json, const [
        'destination_branch_name',
        'destination_hub',
        'destination_name',
        'destination_hub_name',
      ]),
      flightDate: OutboundDataParse.firstNonEmptyString(json, const [
        'flight_date',
        'departure_date',
        'airway_bill_date',
      ]),
      shipmentCount: OutboundDataParse.optionalInt(json, 'shipment_count'),
      shipments: ManifestShipmentRef.listFromDynamic(json['shipments']),
      bags: ManifestBagRef.listFromDynamic(json['bags']),
    );
  }

  factory LinehaulDetail.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return LinehaulDetail.fromJson(map);
    return const LinehaulDetail();
  }

  /// Best ref for `getlinehauldetails` — API expects `mawb_no` when available.
  String? get detailLookupRef {
    final mawb = mawbNo?.trim();
    if (mawb != null && mawb.isNotEmpty) return mawb;
    final awb = airwayBillNo?.trim();
    if (awb != null && awb.isNotEmpty) return awb;
    final trip = tripNo?.trim();
    if (trip != null && trip.isNotEmpty) return trip;
    final id = linehaulId?.trim();
    if (id != null && id.isNotEmpty && id != '0') return id;
    return null;
  }

  /// Total consignments — API count or parsed shipment rows.
  int get totalConsignments =>
      shipmentCount ?? (shipments.isNotEmpty ? shipments.length : 0);

  String get flightNoAndMode {
    final flight = flightNo?.trim();
    final mode = transportType?.trim();
    if (flight != null &&
        flight.isNotEmpty &&
        mode != null &&
        mode.isNotEmpty) {
      return '$flight / $mode';
    }
    return flight ?? mode ?? '—';
  }

  String? get stdFromDeparture {
    final raw = departureTime?.trim();
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(' ');
    if (parts.length >= 2) return parts.last;
    return raw;
  }

  /// Short lines for snackbar / response panel after `getlinehauldetails`.
  List<String> get summaryLines {
    final lines = <String>[];
    void add(String label, String? v) {
      final t = v?.trim();
      if (t != null && t.isNotEmpty) lines.add('$label: $t');
    }

    add('Trip', tripNo ?? airwayBillNo ?? mawbNo);
    add('Status', status);
    add('Vehicle', vehicleNo);
    add('Driver', driverName);
    add('Bags', noOfBags ?? noOfBoxes);
    add('Weight', totalWeight);
    if (manifests.isNotEmpty) {
      add('Manifests', manifests.map((m) => m.manifestNo).whereType<String>().join(', '));
    }
    return lines;
  }

  Map<String, dynamic> toJson() => {
        if (linehaulId != null) 'linehaul_id': linehaulId,
        if (tripNo != null) 'trip_no': tripNo,
        if (origin != null) 'origin': origin,
        if (destination != null) 'destination': destination,
        if (transportType != null) 'transport_type': transportType,
        if (airline != null) 'airline': airline,
        if (flightNo != null) 'flight_no': flightNo,
        if (mawbNo != null) 'mawb_no': mawbNo,
        if (airwayBillNo != null) 'airway_bill_no': airwayBillNo,
        if (vehicleNo != null) 'vehicle_no': vehicleNo,
        if (driverName != null) 'driver_name': driverName,
        if (driverMobile != null) 'driver_mobile': driverMobile,
        if (ewayBill != null) 'eway_bill': ewayBill,
        if (remarks != null) 'remarks': remarks,
        if (status != null) 'status': status,
        if (noOfBoxes != null) 'no_of_boxes': noOfBoxes,
        if (noOfBags != null) 'no_of_bags': noOfBags,
        if (totalWeight != null) 'total_weight': totalWeight,
        if (totalBillingWeight != null) 'total_billing_weight': totalBillingWeight,
        if (departureTime != null) 'departure_time': departureTime,
        if (arrivalTime != null) 'arrival_time': arrivalTime,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
        if (manifestIds != null) 'manifest_ids': manifestIds,
        if (manifestCodes != null) 'manifest_codes': manifestCodes,
        'manifests': manifests.map((e) => e.toJson()).toList(),
        if (originBranchName != null) 'origin_branch_name': originBranchName,
        if (destinationBranchName != null)
          'destination_branch_name': destinationBranchName,
        if (flightDate != null) 'flight_date': flightDate,
        if (shipmentCount != null) 'shipment_count': shipmentCount,
        'shipments': shipments.map((e) => e.toJson()).toList(),
        'bags': bags.map((e) => e.toJson()).toList(),
      };
}
