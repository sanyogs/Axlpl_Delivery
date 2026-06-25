import 'package:axlpl_delivery/app/data/models/outbound/linehaul_consignment_summary_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/linehaul_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_bag_ref_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_shipment_ref_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LinehaulDetail', () {
    test('parses shipments, bags, and branch names from getlinehauldetails', () {
      final detail = LinehaulDetail.fromJson({
        'id': '12',
        'origin': '75',
        'destination': '39',
        'origin_branch_name': 'Vishakhapatnam Hub',
        'destination_branch_name': 'Mumbai Hub',
        'transport_type': 'Air',
        'airline': '2',
        'flight_no': '6e585',
        'mawb_no': '31270236121',
        'no_of_boxes': '6',
        'no_of_bags': '1',
        'departure_time': '2024-06-24 22:30:00',
        'arrival_time': '2024-06-25 15:00:00',
        'total_weight': '5111.50',
        'shipment_count': 6,
        'bags': [
          {
            'id': '200',
            'bag_code': 'BAG20240624114247',
            'metal_seal_no': 'MASTER001',
          },
        ],
        'shipments': [
          {
            'id': '222331782200551',
            'shipment_invoice_no': '12',
            'sender_name': 'MAHALAKSHMI HALLMARK',
            'receiver_name': 'M.A. JEWELLERS',
            'no_of_package': '1',
            'net_weight': '97.20',
            'gross_weight': '150.00',
            'payment_mode': 'PREPAID',
            'bag_code': 'BAG20240624114247',
            'destination_city': 'Mumbai Hub',
          },
        ],
      });

      expect(detail.originBranchName, 'Vishakhapatnam Hub');
      expect(detail.destinationBranchName, 'Mumbai Hub');
      expect(detail.mawbNo, '31270236121');
      expect(detail.flightNoAndMode, '6e585 / Air');
      expect(detail.stdFromDeparture, '22:30:00');
      expect(detail.totalConsignments, 6);
      expect(detail.bags, hasLength(1));
      expect(detail.shipments, hasLength(1));
      expect(detail.shipments.first.senderName, 'MAHALAKSHMI HALLMARK');
      expect(detail.shipments.first.paidDisplay, 'PREPAID');
    });
  });

  group('LinehaulConsignmentSummary', () {
    test('builds bag-level rows from bags and shipments', () {
      final bags = [
        const ManifestBagRef(
          id: '200',
          bagCode: 'BAG20240624114247',
          metalSealNo: 'MASTER001',
        ),
      ];
      final shipments = [
        const ManifestShipmentRef(
          id: '222331782200551',
          bagCode: 'BAG20240624114247',
          senderName: 'Sender',
          receiverName: 'Receiver',
          numberOfParcel: '1',
          grossWeight: '150.00',
          paymentMode: 'PREPAID',
          destinationCity: 'Mumbai Hub',
        ),
      ];

      final rows = LinehaulConsignmentSummary.build(
        bags: bags,
        shipments: shipments,
        defaultDestHub: 'Mumbai Hub',
      );

      expect(rows, hasLength(1));
      expect(rows.first.masterBag, 'MASTER001');
      expect(rows.first.bagNo, 'BAG20240624114247');
      expect(rows.first.consignmentCount, 1);
      expect(rows.first.boxCount, 1);
      expect(rows.first.shipmentType, 'PREPAID');
    });
  });
}
