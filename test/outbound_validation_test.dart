import 'package:axlpl_delivery/app/modules/outbound_common/outbound_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboundValidation', () {
    test('validateBagId rejects zero and empty', () {
      expect(OutboundValidation.validateBagId(null), isNotNull);
      expect(OutboundValidation.validateBagId(''), isNotNull);
      expect(OutboundValidation.validateBagId('0'), isNotNull);
      expect(OutboundValidation.validateBagId('42'), isNull);
      expect(OutboundValidation.validateBagId('BAG20260515154014'), isNull);
    });

    test('validateManifestId accepts manifest codes', () {
      expect(OutboundValidation.validateManifestId('MUM075'), isNull);
      expect(OutboundValidation.validateManifestId('0'), isNotNull);
    });

    test('validateCreateBagPayload rejects bag_id 0 without bag code', () {
      expect(
        OutboundValidation.validateCreateBagPayload({'bag_id': 0}),
        isNotNull,
      );
      expect(
        OutboundValidation.validateCreateBagPayload({
          'bag_id': 0,
          'bag_code': 'BAG20260515154014',
        }),
        isNull,
      );
      expect(
        OutboundValidation.validateCreateBagPayload({'bag_id': '12', 'bag_code': 'X'}),
        isNull,
      );
    });

    test('validateLinehaulId accepts trip_no', () {
      expect(OutboundValidation.validateLinehaulId('LH1778842087'), isNull);
    });
  });
}
