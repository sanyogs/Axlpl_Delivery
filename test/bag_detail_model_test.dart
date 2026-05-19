import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses live getbagdetails object with nested items', () {
    const sample = {
      'id': '200',
      'bag_code': 'BAG20260518152744831',
      'metal_seal_no': 'MSeal825411779084407',
      'origin_branch_id': '37',
      'destination_sector_id': '95',
      'created_by': '1',
      'created_at': '2026-05-18 15:27:44',
      'updated_at': null,
      'shipment_count': 1,
      'manifest_status': 'Not Manifested',
      'items': [
        {
          'id': '1099',
          'bag_id': '200',
          'shipment_id': '825411779084407',
          'created_at': '2026-05-18 15:27:44',
          'updated_at': null,
          'shipment_invoice_no': '1',
          'shipment_status': 'Manifest Created',
        },
      ],
    };

    final detail = BagDetail.fromJson(sample);
    expect(detail.id, '200');
    expect(detail.bagCode, 'BAG20260518152744831');
    expect(detail.metalSealNo, 'MSeal825411779084407');
    expect(detail.destinationSectorId, '95');
    expect(detail.shipmentCount, 1);
    expect(detail.manifestStatus, 'Not Manifested');
    expect(detail.items, hasLength(1));
    expect(detail.items.first.shipmentId, '825411779084407');
    expect(detail.items.first.shipmentStatus, 'Manifest Created');
    expect(detail.summaryLines.any((l) => l.contains('825411779084407')), isTrue);
  });

  test('parses optional branch and sector names from API', () {
    const sample = {
      'bag_code': 'BAG1',
      'origin_branch_id': '37',
      'origin_branch_name': 'Mumbai Hub',
      'destination_sector_id': '95',
      'destination_sector_name': 'Delhi Sector',
    };
    final detail = BagDetail.fromJson(sample);
    expect(detail.originBranchName, 'Mumbai Hub');
    expect(detail.destinationSectorName, 'Delhi Sector');
  });
}
