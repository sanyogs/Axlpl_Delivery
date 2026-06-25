import 'package:axlpl_delivery/app/data/models/outbound/pickup_detail_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses live getpickupdetail payload', () {
    const sample = {
      'id': '286',
      'mawb_no': '31229324256',
      'hub_id': '1',
      'picked_by': null,
      'pickup_date': '2026-06-09',
      'pickup_time': '13:24:00',
      'created_at': '2026-06-09 13:18:32',
      'updated_at': '2026-06-09 13:24:23',
      'origin_hub': 'Hyderabad',
      'destination_hub': 'Mumbai',
      'origin_branch': 'SURAT',
      'destination_branch': 'Mumbai',
      'flight_no': '6E5213',
      'total_shipments': 13,
      'shipment_list': [
        {
          'shipment_id': '825411779084407',
          'shipment_invoice_no': '1',
          'status': 'Hub In',
          'sender_name': 'prajakta rajeshirke',
          'receiver_name': 'receiver_version',
        },
        {
          'shipment_id': '123456789',
          'shipment_invoice_no': '2450000000000000',
          'status': 'Not Picked',
          'sender_name': 'prajakta rajeshirke',
          'receiver_name': 'Version Next',
        },
      ],
    };

    final detail = PickupDetail.fromJson(sample);
    expect(detail.id, '286');
    expect(detail.mawbNo, '31229324256');
    expect(detail.hubBranchLabel, 'Hyderabad');
    expect(detail.pickupDateTimeLabel, '2026-06-09 13:24:00');
    expect(detail.manifestedCount, 13);
    expect(detail.shipmentList, hasLength(2));
    expect(detail.shipmentList.first.docketNo, '825411779084407');
    expect(detail.shipmentList.first.displayCodeSuffix, '1');
  });

  test('groups loose shipments for sector pickup report PDF', () {
    final detail = PickupDetail.fromJson({
      'id': '423',
      'mawb_no': 'MAWB562001',
      'origin_hub': 'Amritsar',
      'pickup_date': '2024-06-25',
      'pickup_time': '14:05:33',
      'total_shipments': 2,
      'shipment_list': [
        {
          'shipment_id': '91338731723200028',
          'shipment_invoice_no': 'SC-03',
          'destination_city': 'Amritsar',
        },
        {
          'shipment_id': '91338731723200029',
          'shipment_invoice_no': 'SC-04',
          'destination_city': 'Jalandhar',
        },
      ],
    });

    final groups = SectorPickupReportBagGroup.fromPickupDetail(detail);
    expect(groups, hasLength(1));
    expect(groups.first.bagLabel, 'Loose shipments');
    expect(groups.first.shipmentCount, 2);
    expect(groups.first.shipments.first.destHubDisplay, 'Amritsar');
  });

  test('groups shipments by bag code when present', () {
    final detail = PickupDetail.fromJson({
      'id': '100',
      'shipment_list': [
        {
          'shipment_id': 'A1',
          'bag_code': 'BAG001',
          'destination_city': 'Mumbai',
        },
        {
          'shipment_id': 'A2',
          'bag_code': 'BAG001',
          'destination_city': 'Mumbai',
        },
        {
          'shipment_id': 'B1',
          'bag_code': 'BAG002',
          'destination_city': 'Delhi',
        },
      ],
    });

    final groups = SectorPickupReportBagGroup.fromPickupDetail(detail);
    expect(groups, hasLength(2));
    expect(groups[0].bagLabel, 'BAG001');
    expect(groups[0].shipmentCount, 2);
    expect(groups[1].bagLabel, 'BAG002');
    expect(groups[1].shipmentCount, 1);
  });
}
