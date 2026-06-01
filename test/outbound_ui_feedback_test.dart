import 'package:axlpl_delivery/app/modules/outbound_common/outbound_ui_feedback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serverMessageFromData reads injected __server_message', () {
    expect(
      OutboundUiFeedback.serverMessageFromData({
        '__server_message': 'Bag locked successfully',
      }),
      'Bag locked successfully',
    );
  });

  test('serverMessageFromData reads message on payload map', () {
    expect(
      OutboundUiFeedback.serverMessageFromData({
        'message': 'Shipment added',
        'bag_code': 'BAG1',
      }),
      'Shipment added',
    );
  });
}
