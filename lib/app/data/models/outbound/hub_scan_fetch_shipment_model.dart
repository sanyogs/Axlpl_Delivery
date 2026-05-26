import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Shipment payload from `hubScanFetchShipment` (`{ status, shipment }`).
class HubScanFetchedShipment {
  const HubScanFetchedShipment({
    this.id,
    this.docketNo,
    this.receiverName,
    this.clientCode,
    this.numberOfParcel,
    this.originPincode,
    this.destinationPincode,
    this.destinationCity,
    this.actualValue,
    this.scannedCount,
  });

  final String? id;
  final String? docketNo;
  final String? receiverName;
  final String? clientCode;
  final String? numberOfParcel;
  final String? originPincode;
  final String? destinationPincode;
  final String? destinationCity;
  final String? actualValue;
  final String? scannedCount;

  /// Connote sent to `hubscan` as `docket_no` (prefer API id / connote).
  String get connoteForScan {
    final id = this.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    return docketNo?.trim() ?? '';
  }

  factory HubScanFetchedShipment.fromJson(Map<String, dynamic> json) {
    return HubScanFetchedShipment(
      id: OutboundDataParse.firstNonEmptyString(json, const ['id', 'shipment_id']),
      docketNo: OutboundDataParse.optionalString(json, 'docket_no'),
      receiverName: OutboundDataParse.optionalString(json, 'receiver_name'),
      clientCode: OutboundDataParse.optionalString(json, 'client_code'),
      numberOfParcel: OutboundDataParse.optionalString(json, 'number_of_parcel'),
      originPincode: OutboundDataParse.optionalString(json, 'origin_pincode'),
      destinationPincode:
          OutboundDataParse.optionalString(json, 'destination_pincode'),
      destinationCity: OutboundDataParse.optionalString(json, 'destination_city'),
      actualValue: HubScanFetchedShipment._stringFromJson(json, 'actual_value'),
      scannedCount: HubScanFetchedShipment._stringFromJson(json, 'scanned_count'),
    );
  }

  factory HubScanFetchedShipment.fromDynamic(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map != null) return HubScanFetchedShipment.fromJson(map);
    return const HubScanFetchedShipment();
  }

  static String? _stringFromJson(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static HubScanFetchResult parseResponse(dynamic data) {
    final map = OutboundDataParse.asStringKeyedMap(data);
    if (map == null) {
      return const HubScanFetchResult();
    }
    final status = map['status']?.toString().trim().toLowerCase();
    final message = OutboundDataParse.optionalString(map, 'message');
    final shipmentRaw = map['shipment'] ?? map['data'];
    if (status == 'fail' || status == 'error') {
      return HubScanFetchResult(
        serverMessage: message ?? '',
        isFailure: true,
      );
    }
    final shipment = HubScanFetchedShipment.fromDynamic(shipmentRaw);
    return HubScanFetchResult(
      shipment: shipment.connoteForScan.isNotEmpty ? shipment : null,
      serverMessage: message,
    );
  }
}

class HubScanFetchResult {
  const HubScanFetchResult({
    this.shipment,
    this.serverMessage,
    this.isFailure = false,
  });

  final HubScanFetchedShipment? shipment;
  final String? serverMessage;
  final bool isFailure;
}
