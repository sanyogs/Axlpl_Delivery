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

  test('selects requested M/Bag from list-style API client wrapper', () {
    const sample = {
      'items': [
        {
          'bag_code': 'BAG20260518152744831',
          'origin_branch_id': '37',
          'destination_sector_id': '95',
        },
        {
          'm_bag_code': 'G2026061021223737',
          'metal_seal_no': 'MSeal1021223737',
          'origin_branch_id': '27',
          'destination_sector_id': '39',
          'shipment_count': 2,
        },
      ],
      '__server_message': 'Bag details retrieved successfully',
    };

    final detail = BagDetail.fromDynamic(
      sample,
      requestedBagCode: 'G2026061021223737',
    );

    expect(detail.bagCode, 'G2026061021223737');
    expect(detail.metalSealNo, 'MSeal1021223737');
    expect(detail.originBranchId, '27');
    expect(detail.destinationSectorId, '39');
    expect(detail.shipmentCount, 2);
  });

  test('resolves scanned M/Bag from metal_seal_no when bag_code is absent', () {
    const sample = {
      'metal_seal_no': 'G20260610121223737',
      'origin_branch_id': '27',
      'destination_sector_id': '39',
      'shipment_count': 2,
      'items': [
        {
          'shipment_id': '825411779084407',
          'shipment_invoice_no': '1',
        },
      ],
      '__server_message': 'Bag details retrieved successfully',
    };

    final detail = BagDetail.fromDynamic(
      sample,
      requestedBagCode: 'G20260610121223737',
    );

    expect(detail.bagCode, 'G20260610121223737');
    expect(detail.metalSealNo, 'G20260610121223737');
    expect(detail.originBranchId, '27');
    expect(detail.destinationSectorId, '39');
    expect(detail.shipmentCount, 2);
  });

  test('prefers server bag_code over scanned M/Bag ref', () {
    const sample = {
      'bag_code': 'BAG20260610121223737',
      'metal_seal_no': 'mskb',
      'origin_branch_id': '71',
      'destination_sector_id': '62',
    };

    final detail = BagDetail.fromDynamic(
      sample,
      requestedBagCode: 'mskb',
    );

    expect(detail.bagCode, 'BAG20260610121223737');
    expect(detail.metalSealNo, 'mskb');
  });

  test('parses double-nested getbagdetails wrapper from live API', () {
    const sample = {
      'status': 'success',
      'message': 'Bag details retrieved successfully',
      'data': {
        'status': 'success',
        'message': 'Bag details fetched successfully',
        'data': {
          'bag': {
            'id': '390',
            'bag_code': 'BAG20260610121223737',
            'metal_seal_no': 'mskb',
            'origin_branch_id': '71',
            'destination_sector_id': '62',
            'origin_branch_name': 'AGRA',
            'destination_city_name': 'Ahmedabad crossing',
            'gross_weight': '200.00',
          },
          'items': [
            {
              'shipment_id': '600421776103388',
              'shipment_invoice_no': '21102001',
              'sender_name': 'version next',
              'receiver_name': 'tester co',
              'consignee_code': '3305',
              'city_name': 'Mumbai',
              'number_of_parcel': '1',
              'invoice_val': '354.00',
              'gross_weight': '200.00',
              'volumetric_weight': '100.00',
            },
          ],
        },
      },
    };

    final detail = BagDetail.fromDynamic(sample, requestedBagCode: 'mskb');

    expect(detail.id, '390');
    expect(detail.bagCode, 'BAG20260610121223737');
    expect(detail.metalSealNo, 'mskb');
    expect(detail.originBranchName, 'AGRA');
    expect(detail.destinationSectorName, 'Ahmedabad crossing');
    expect(detail.grossWeight, '200.00');
    expect(detail.items, hasLength(1));
    expect(detail.items.first.shipmentId, '600421776103388');
    expect(detail.items.first.destinationCity, 'Mumbai');
    expect(detail.items.first.consigneeCode, '3305');
    expect(detail.items.first.invoiceVal, '354.00');
    expect(detail.items.first.volumetricWeight, '100.00');
  });

  test('parses live getbagdetails nested data.bag wrapper from curl', () {
    const sample = {
      'status': 'success',
      'message': 'Bag details fetched successfully',
      'data': {
        'bag': {
          'id': '200',
          'bag_code': 'BAG20260518152744831',
          'metal_seal_no': 'MSeal825411779084407',
          'origin_branch_id': '37',
          'destination_sector_id': '95',
          'origin_branch_name': 'KOLKATTA',
          'destination_city_name': 'Puttur',
          'gross_weight': '11.00',
        },
        'items': [
          {
            'shipment_id': '825411779084407',
            'shipment_invoice_no': '1',
            'sender_name': 'prajakta rajeshirke',
            'receiver_name': 'receiver_version',
            'city_name': 'Mumbai',
            'number_of_parcel': '1',
            'gross_weight': '11.00',
          },
        ],
      },
      '__server_message': 'Bag details retrieved successfully',
    };

    final detail = BagDetail.fromDynamic(
      sample,
      requestedBagCode: 'BAG20260518152744831',
    );

    expect(detail.bagCode, 'BAG20260518152744831');
    expect(detail.metalSealNo, 'MSeal825411779084407');
    expect(detail.originBranchId, '37');
    expect(detail.items, hasLength(1));
    expect(detail.items.first.shipmentId, '825411779084407');
  });

  test('parses live nested data.bag wrapper for G M/Bag in metal_seal_no', () {
    const sample = {
      'status': 'success',
      'message': 'Bag details fetched successfully',
      'data': {
        'bag': {
          'id': '300',
          'metal_seal_no': 'G20260610121223737',
          'origin_branch_id': '27',
          'destination_sector_id': '39',
          'gross_weight': '5.00',
        },
        'items': [
          {'shipment_id': '123', 'shipment_invoice_no': '1'},
        ],
      },
      '__server_message': 'Bag details retrieved successfully',
    };

    final detail = BagDetail.fromDynamic(
      sample,
      requestedBagCode: 'G20260610121223737',
    );

    expect(detail.bagCode, 'G20260610121223737');
    expect(detail.originBranchId, '27');
    expect(detail.destinationSectorId, '39');
    expect(detail.items, hasLength(1));
  });

  test('parses created_by_name and summary helpers for bagging details', () {
    const sample = {
      'bag_code': 'BAG1',
      'metal_seal_no': 'SEAL1',
      'origin_branch_name': 'Vishakapatnam',
      'destination_sector_name': 'Mumbai',
      'created_by_name': 'SURAJ BAIT',
      'created_at': '2026-06-25 11:42:00',
      'manifest_status': 'Not Manifested',
      'gross_weight': '5111.50',
      'shipment_count': 2,
      'items': [
        {
          'shipment_id': '111',
          'shipment_invoice_no': '2015',
          'no_of_package': '1',
          'total_weight': '100',
        },
        {
          'shipment_id': '222',
          'shipment_invoice_no': 'DC-89',
          'no_of_package': '1',
          'total_weight': '50',
        },
      ],
    };

    final detail = BagDetail.fromJson(sample);
    expect(detail.createdByName, 'SURAJ BAIT');
    expect(detail.createdByDisplay, 'SURAJ BAIT');
    expect(detail.totalBoxes, 2);
    expect(detail.totalWeightDisplay, '5111.50');
    expect(detail.isOpenForChanges, isTrue);
    expect(detail.shipmentCountDisplay, 2);
  });
}
