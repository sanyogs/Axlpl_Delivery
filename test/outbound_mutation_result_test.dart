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

    test('effectiveLinehaulRef uses trip_no when linehaul_id is 0', () {
      final r = OutboundMutationResult.fromDynamic({
        'linehaul_id': 0,
        'trip_no': 'LH1778841961',
      });
      expect(r.linehaulId, '0');
      expect(r.tripNo, 'LH1778841961');
      expect(r.effectiveLinehaulRef, 'LH1778841961');
    });

    test('effectiveLinehaulRef prefers trip_no over numeric linehaul_id', () {
      final r = OutboundMutationResult.fromDynamic({
        'linehaul_id': 456,
        'trip_no': 'LH1781776125',
      });
      expect(r.effectiveLinehaulRef, 'LH1781776125');
    });

    test('numericLinehaulIdForEdit returns assign id for editlinehaul', () {
      final r = OutboundMutationResult.fromDynamic({
        'linehaul_id': 460,
        'trip_no': 'LH1781778629',
      });
      expect(r.numericLinehaulIdForEdit, '460');
    });

    test('fromDynamic unwraps nested data object', () {
      final r = OutboundMutationResult.fromDynamic({
        'status': 'success',
        'data': {
          'linehaul_id': 0,
          'trip_no': 'LH1778841961',
        },
      });
      expect(r.effectiveLinehaulRef, 'LH1778841961');
    });
  });
}
