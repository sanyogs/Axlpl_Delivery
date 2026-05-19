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
