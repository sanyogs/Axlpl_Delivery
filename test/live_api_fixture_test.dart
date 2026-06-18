import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/outbound_linehaul_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures captured live via curl against production QA (2026-06-18).
void main() {
  group('AHM002 live getmanifestdetails', () {
    const live = {
      'id': '456',
      'manifest_no': 'AHM002',
      'origin_branch': '71',
      'destination_branch': '62',
      'created_by': '148',
      'created_at': '2026-06-17 18:47:36',
      'updated_at': '2026-06-17 18:47:36',
      'origin_branch_name': 'Agra',
      'destination_branch_name': 'Ahmedabad crossing',
      'bags': [
        {
          'id': '390',
          'bag_code': 'BAG20260610121223737',
          'metal_seal_no': 'mskb',
        },
      ],
      'shipments': [
        {
          'id': '600421776103388',
          'shipment_invoice_no': '21102001',
          'shipment_status': 'In Transit',
          'bag_id': '390',
          'bag_code': 'BAG20260610121223737',
          'sender_name': 'version next',
          'receiver_name': 'tester co',
          'destination_city': 'Mumbai',
          'total_weight': '200',
          'no_of_package': '1',
        },
      ],
    };

    test('parses manifest, weight, and created_at', () {
      final detail = ManifestDetail.fromDynamic(live);
      expect(detail.manifestNo, 'AHM002');
      expect(detail.manifestId, '456');
      expect(detail.createdAt, '2026-06-17 18:47:36');
      expect(detail.hasContent, isTrue);
      expect(detail.shipments.single.grossWeight, '200');

      final total = detail.shipments.fold<double>(
        0,
        (sum, s) => sum + (double.tryParse(s.grossWeight ?? '') ?? 0),
      );
      expect(total, 200);
    });
  });

  group('assignlinehaul live response', () {
    test('effectiveLinehaulRef prefers LH trip over numeric linehaul_id', () {
      final r = OutboundMutationResult.fromDynamic({
        'linehaul_id': 456,
        'trip_no': 'LH1781776125',
      });
      expect(r.effectiveLinehaulRef, 'LH1781776125');
    });

    test('effectiveLinehaulRef uses trip when linehaul_id is 0', () {
      final r = OutboundMutationResult.fromDynamic({
        'linehaul_id': 0,
        'trip_no': 'LH1778841961',
      });
      expect(r.effectiveLinehaulRef, 'LH1778841961');
    });
  });

  group('printmanifestdata AHM002 live', () {
    const livePrint = {
      'id': '456',
      'manifest_no': 'AHM002',
      'origin_branch': '71',
      'destination_branch': '62',
      'created_by': '148',
      'created_at': '2026-06-17 18:47:36',
      'updated_at': '2026-06-17 18:47:36',
      'origin_branch_name': 'Agra',
      'destination_branch_name': 'Ahmedabad crossing',
      'shipments': [
        {
          'id': '600421776103388',
          'shipment_invoice_no': '21102001',
          'shipment_status': 'In Transit',
          'bag_code': 'BAG20260610121223737',
        },
      ],
    };

    test('print payload hasContent without bags array', () {
      final detail = ManifestDetail.fromDynamic(livePrint);
      expect(detail.manifestNo, 'AHM002');
      expect(detail.bags, isEmpty);
      expect(detail.shipments, hasLength(1));
      expect(detail.hasContent, isTrue);
    });
  });

  group('linehaul manifest auto-fill AHM002', () {
    const live = {
      'id': '456',
      'manifest_no': 'AHM002',
      'created_at': '2026-06-17 18:47:36',
      'bags': [
        {
          'id': '390',
          'bag_code': 'BAG20260610121223737',
          'metal_seal_no': 'mskb',
        },
      ],
      'shipments': [
        {
          'id': '600421776103388',
          'bag_code': 'BAG20260610121223737',
          'total_weight': '200',
        },
      ],
    };

    test('bag table uses shipment weight when bag weight missing', () {
      final detail = ManifestDetail.fromDynamic(live);
      final rows = LinehaulBagTableRow.fromManifestDetail(detail);
      expect(rows, hasLength(1));
      expect(rows.single.bagNumber, 'BAG20260610121223737');
      expect(rows.single.weight, '200');
    });
  });
}
