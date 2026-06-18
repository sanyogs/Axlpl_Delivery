import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/manifest_session_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const liveBagDetails = {
    'status': 'success',
    'message': 'Bag details retrieved successfully',
    'data': {
      'status': 'success',
      'message': 'Bag details fetched successfully',
      'data': {
        'bag': {
          'id': '458',
          'bag_code': 'BAG20260618171826757',
          'metal_seal_no': 'bag9998979695',
          'origin_branch_id': '75',
          'destination_sector_id': '75',
          'origin_branch_name': 'MUMBAI',
          'destination_city_name': 'Mumbai',
          'gross_weight': '11.00',
        },
        'items': [
          {
            'shipment_id': '9998979695',
            'shipment_invoice_no': '1342341234234',
            'sender_name': 'version next technology',
            'receiver_name': 'Version Next',
            'consignee_code': '10232',
            'city_name': 'Mumbai',
            'number_of_parcel': '1',
            'invoice_val': '845.47',
            'gross_weight': '11.00',
            'volumetric_weight': '10.00',
          },
        ],
      },
    },
  };

  test('ManifestBagSessionRow uses bag_code and nested gross_weight', () {
    final detail = BagDetail.fromDynamic(
      liveBagDetails,
      requestedBagCode: 'BAG20260618171826757',
    );
    final row = ManifestBagSessionRow.fromBagDetail(
      detail,
      branchLabel: (id) => id ?? '—',
      rawData: liveBagDetails,
      scannedBagCode: 'bag9998979695',
    );

    expect(row.bagCode, detail.bagCode);
    expect(row.weight, detail.grossWeight);
    expect(row.originLabel, detail.originBranchName);
  });

  test('ManifestShipmentSessionRow maps item parcel and weights', () {
    final detail = BagDetail.fromDynamic(
      liveBagDetails,
      requestedBagCode: 'BAG20260618171826757',
    );
    final item = detail.items.single;
    final line = ManifestShipmentSessionRow.fromBagDetailItem(
      item,
      bagCode: detail.bagCode!,
      originBranchName: detail.originBranchName,
    );

    expect(line.bagNumber, detail.bagCode);
    expect(line.boxNo, item.noOfPackage);
    expect(line.consignmentNo, item.shipmentId);
    expect(line.origin, detail.originBranchName);
    expect(line.pcs, item.noOfPackage);
    expect(line.grossWeight, item.totalWeight);
    expect(line.volumetricWeight, item.volumetricWeight);
    expect(line.invVal, item.invoiceVal);
    expect(line.consigneeCode, item.consigneeCode);
    expect(line.consigneeName, item.receiverName);
    expect(line.cityName, item.destinationCity);
    expect(line.description, isNull);
  });
}
