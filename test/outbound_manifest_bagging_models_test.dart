import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/lock_bag_response_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_report_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/outbound_manifest_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses live baggingreport object', () {
    const sample = {
      'id': '200',
      'bag_code': 'BAG20260518152744831',
      'metal_seal_no': 'MSeal825411779084407',
      'origin_branch_id': '37',
      'destination_sector_id': '95',
      'origin_branch_name': 'KOLKATTA',
      'destination_city_name': 'Puttur',
      'items': [
        {
          'shipment_id': '825411779084407',
          'shipment_invoice_no': '1',
          'receiver_name': 'receiver_version',
          'destination_city': 'Mumbai',
          'total_weight': '11.00',
          'no_of_package': '1',
        },
      ],
    };

    final report = BaggingReport.fromJson(sample);
    expect(report.bagCode, 'BAG20260518152744831');
    expect(report.items, hasLength(1));
    expect(report.items.first.shipmentId, '825411779084407');
  });

  test('parses live lockbag object', () {
    const sample = {
      'bag_id': '200',
      'bag_code': 'BAG20260518152744831',
      'status': 'Locked',
    };

    final locked = LockBagResponse.fromJson(sample);
    expect(locked.isLocked, isTrue);
    expect(locked.bagCode, 'BAG20260518152744831');
  });

  test('parses live getmanifestdetails object', () {
    const sample = {
      'id': '205',
      'manifest_no': 'MUM094',
      'origin_branch': '37',
      'destination_branch': '75',
      'origin_branch_name': 'Kolkatta',
      'destination_branch_name': 'Mumbai',
      'bags': [
        {'id': '200', 'bag_code': 'BAG20260518152744831'},
      ],
      'shipments': [
        {
          'id': '825411779084407',
          'shipment_invoice_no': '1',
          'shipment_status': 'In Transit',
          'bag_code': 'BAG20260518152744831',
        },
      ],
    };

    final detail = ManifestDetail.fromJson(sample);
    expect(detail.manifestNo, 'MUM094');
    expect(detail.originBranchId, '37');
    expect(detail.destinationBranchId, '75');
    expect(detail.bags, hasLength(1));
    expect(detail.shipments.first.id, '825411779084407');
  });

    test('parses live listmanifests row', () {
      const sample = {
        'id': '205',
        'manifest_no': 'MUM094',
        'origin_branch': '37',
        'destination_branch': '75',
        'created_at': '2026-05-19 14:59:18',
      };

      final row = OutboundManifestRow.fromJson(sample);
      expect(row.manifestNo, 'MUM094');
      expect(row.originBranch, '37');
    });

    test('parses MUM208 manifest with shipment total_weight (live API)', () {
      const sample = {
        'id': '381',
        'manifest_no': 'MUM208',
        'origin_branch': '47',
        'destination_branch': '75',
        'created_by': '187',
        'created_at': '2026-06-08 22:45:01',
        'updated_at': '2026-06-08 22:45:01',
        'origin_branch_name': 'Vijaywada',
        'destination_branch_name': 'Mumbai',
        'bags': [
          {
            'id': '379',
            'bag_code': 'BAG20260608224439',
            'metal_seal_no': 'VAL0074004 VGA TO MUM',
          },
        ],
        'shipments': [
          {
            'id': '188501780927776',
            'shipment_invoice_no': 'NRLV/KI/2627/029',
            'total_weight': '1398',
            'no_of_package': '1',
          },
          {
            'id': '797511780931214',
            'shipment_invoice_no': 'SAI/123',
            'total_weight': '100',
            'no_of_package': '1',
          },
        ],
      };

      final detail = ManifestDetail.fromDynamic(sample);
      expect(detail.manifestNo, 'MUM208');
      expect(detail.createdAt, '2026-06-08 22:45:01');
      expect(detail.bags, hasLength(1));
      expect(detail.bags.first.grossWeight, isNull);
      expect(detail.shipments[0].grossWeight, '1398');
      expect(detail.shipments[1].grossWeight, '100');
      expect(detail.hasContent, isTrue);

      final totalFromShipments = detail.shipments.fold<double>(
        0,
        (sum, s) => sum + (double.tryParse(s.grossWeight ?? '') ?? 0),
      );
      expect(totalFromShipments, 1498);
    });

    test('parses printmanifestdata MUM075 payload', () {
      const sample = {
        'id': '171',
        'manifest_no': 'MUM075',
        'origin_branch': '75',
        'destination_branch': '75',
        'created_by': '81',
        'created_at': '2026-05-15 15:47:10',
        'updated_at': '2026-05-15 15:47:10',
        'origin_branch_name': 'Mumbai',
        'destination_branch_name': 'Mumbai',
        'shipments': [],
      };

      final detail = ManifestDetail.fromDynamic(sample);
      expect(detail.manifestNo, 'MUM075');
      expect(detail.hasContent, isTrue);
    });

  test('parses live manifestreport object', () {
    const sample = {
      'id': '205',
      'manifest_no': 'MUM094',
      'origin_branch': '37',
      'destination_branch': '75',
      'origin_branch_name': 'KOLKATTA',
      'destination_branch_name': 'Mumbai',
      'shipments': [
        {
          'id': '825411779084407',
          'receiver_name': 'receiver_version',
          'destination_city': 'Mumbai',
          'gross_weight': '11.00',
          'volumetric_weight': '10.00',
        },
      ],
      'bags': [
        {
          'id': '200',
          'bag_code': 'BAG20260518152744831',
          'metal_seal_no': 'MSeal825411779084407',
          'gross_weight': '11',
        },
      ],
    };

    final report = ManifestReport.fromJson(sample);
    expect(report.manifestNo, 'MUM094');
    expect(report.bags.first.metalSealNo, 'MSeal825411779084407');
    expect(report.shipments.first.grossWeight, '11.00');
  });
}
