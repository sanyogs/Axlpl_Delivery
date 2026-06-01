import 'package:axlpl_delivery/app/modules/outbound_common/outbound_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboundValidation', () {
    test('validateBagId is non-blocking', () {
      expect(OutboundValidation.validateBagId(null), isNull);
      expect(OutboundValidation.validateBagId(''), isNull);
      expect(OutboundValidation.validateBagId('0'), isNull);
      expect(OutboundValidation.validateBagId('42'), isNull);
      expect(OutboundValidation.validateBagId('BAG20260515154014'), isNull);
    });

    test('validateManifestId is non-blocking', () {
      expect(OutboundValidation.validateManifestId('MUM075'), isNull);
      expect(OutboundValidation.validateManifestId('0'), isNull);
    });

    test('validateCreateBagPayload is non-blocking', () {
      expect(
        OutboundValidation.validateCreateBagPayload({'bag_id': 0}),
        isNull,
      );
      expect(
        OutboundValidation.validateCreateBagPayload({
          'bag_id': 0,
          'bag_code': 'BAG20260515154014',
        }),
        isNull,
      );
      expect(
        OutboundValidation.validateCreateBagPayload(
          {'bag_id': '12', 'bag_code': 'X'},
        ),
        isNull,
      );
    });

    test('validateLinehaulId accepts trip_no', () {
      expect(OutboundValidation.validateLinehaulId('LH1778842087'), isNull);
    });
  });
}
