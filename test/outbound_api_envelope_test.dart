import 'package:axlpl_delivery/app/data/models/outbound/outbound_api_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses mutation fail envelope from addshipmenttobag', () {
    const sample = {
      'status': 'fail',
      'message': 'Shipment already bagged in Bag: BAG20260518152744831',
      'data': {},
      'error_code': 422,
    };

    final envelope = OutboundApiEnvelope.fromJson(sample);
    expect(envelope.isFail, isTrue);
    expect(envelope.isSuccess, isFalse);
    expect(envelope.message, contains('already bagged'));
    expect(envelope.errorCode, 422);
  });
}
