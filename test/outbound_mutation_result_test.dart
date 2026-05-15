import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboundMutationResult', () {
    test('hasInvalidBagId when bag_id is 0', () {
      final r = OutboundMutationResult.fromDynamic({
        'bag_id': 0,
        'bag_code': 'TEST',
      });
      expect(r.bagId, '0');
      expect(r.hasInvalidBagId, isTrue);
    });

    test('hasInvalidBagId when bag_id is negative', () {
      final r = OutboundMutationResult.fromDynamic({'bag_id': -1});
      expect(r.hasInvalidBagId, isTrue);
    });

    test('valid bag_id is not invalid', () {
      final r = OutboundMutationResult.fromDynamic({'bag_id': 42});
      expect(r.hasInvalidBagId, isFalse);
      expect(r.bagIdInt, 42);
    });

    test('manifest and linehaul ids parse from map', () {
      final r = OutboundMutationResult.fromDynamic({
        'manifest_id': '153',
        'linehaul_id': '129',
      });
      expect(r.manifestId, '153');
      expect(r.linehaulId, '129');
    });
  });
}
