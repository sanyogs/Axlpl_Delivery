import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_fetch_shipment_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HubScanFetchedShipment.parseResponse', () {
    test('parses success shipment', () {
      final result = HubScanFetchedShipment.parseResponse({
        'status': 'success',
        'shipment': {
          'id': 'CN123',
          'docket_no': 'DK456',
          'receiver_name': 'Jane',
          'client_code': 'ACME',
          'number_of_parcel': '2',
          'origin_pincode': '110001',
          'destination_pincode': '400001',
          'destination_city': 'Mumbai',
          'actual_value': '1.5',
          'scanned_count': '1',
        },
      });

      expect(result.isFailure, isFalse);
      expect(result.shipment, isNotNull);
      expect(result.shipment!.connoteForScan, 'CN123');
      expect(result.shipment!.clientCode, 'ACME');
      expect(result.shipment!.destinationCity, 'Mumbai');
    });

    test('treats fail status as failure', () {
      final result = HubScanFetchedShipment.parseResponse({
        'status': 'fail',
        'message': 'Not found',
      });

      expect(result.isFailure, isTrue);
      expect(result.serverMessage, 'Not found');
      expect(result.shipment, isNull);
    });

    test('uses docket_no when id missing', () {
      final result = HubScanFetchedShipment.parseResponse({
        'status': 'success',
        'shipment': {'docket_no': 'DK99'},
      });

      expect(result.shipment?.connoteForScan, 'DK99');
    });
  });
}
