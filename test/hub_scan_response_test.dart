import 'package:axlpl_delivery/app/data/models/outbound/hub_scan_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses live hubscan success object', () {
    const sample = {
      'success': 'Shipment scanned successfully',
      'shipment_id': '558751776258671',
      'docket_no': '558751776258671',
    };

    final response = HubScanResponse.fromJson(sample);
    expect(response.isOk, isTrue);
    expect(response.successMessage, 'Shipment scanned successfully');
    expect(response.shipmentId, '558751776258671');
    expect(response.docketNo, '558751776258671');
  });
}
