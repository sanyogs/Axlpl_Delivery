import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseShipmentIdsCsv splits comma and whitespace', () {
    expect(
      OutboundApiParams.parseShipmentIdsCsv('825411779084407'),
      ['825411779084407'],
    );
    expect(
      OutboundApiParams.parseShipmentIdsCsv('111, 222 ; 333'),
      ['111', '222', '333'],
    );
  });

  test('createBagBody matches createbag multipart fields', () {
    final body = OutboundApiParams.createBagBody(
      metalSealNo: 'BAG20260525164949980',
      shipmentIdsCsv: '19051998',
    );
    expect(body.containsKey('bag_code'), isFalse);
    expect(body['metal_seal_no'], 'BAG20260525164949980');
    expect(body['shipment_ids'], '19051998');
  });

  test('assignLinehaulBody uses manifest_codes', () {
    final body = OutboundApiParams.assignLinehaulBody(
      manifestCodesCsv: 'MUM094',
      vehicleNo: 'UP78AB1234',
      driverName: 'Driver',
      userId: '148',
    );
    expect(body['manifest_codes'], 'MUM094');
    expect(body['vehicle_no'], 'UP78AB1234');
    expect(body['user_id'], '148');
  });

  test('updateLinehaulStatusBody includes linehaul_id and trip_no', () {
    final body = OutboundApiParams.updateLinehaulStatusBody(
      linehaulRef: 'LH1779101374',
      status: 'ARRIVED',
      userId: '148',
      branchId: '75',
    );
    expect(body['linehaul_id'], 'LH1779101374');
    expect(body['trip_no'], 'LH1779101374');
    expect(body['status'], 'ARRIVED');
  });

  test('deleteLinehaulBody includes trip and airway refs when available', () {
    final body = OutboundApiParams.deleteLinehaulBody(
      linehaulId: '129',
      tripNo: 'LH1779101374',
      mawbNo: 'AWB123',
    );
    expect(body['linehaul_id'], '129');
    expect(body['trip_no'], 'LH1779101374');
    expect(body['mawb_no'], 'AWB123');
  });

  test('deleteLinehaulBody mirrors LH ref as trip_no fallback', () {
    final body = OutboundApiParams.deleteLinehaulBody(
      linehaulId: 'LH1779101374',
    );
    expect(body['linehaul_id'], 'LH1779101374');
    expect(body['trip_no'], 'LH1779101374');
  });

  test('createManifestBody includes transport_mode when set', () {
    final body = OutboundApiParams.createManifestBody(
      bagCodesCsv: 'BAG20260518152744831',
      originBranchId: '37',
      destinationBranchId: '75',
      userId: '1',
      transportMode: 'Airway',
    );
    expect(body['transport_mode'], 'Airway');
    expect(body['bag_codes'], 'BAG20260518152744831');
  });

  test('combineDateTime formats editlinehaul datetime', () {
    expect(
      OutboundApiParams.combineDateTime('2026-06-09', '10:30'),
      '2026-06-09 10:30:00',
    );
    expect(OutboundApiParams.combineDateTime('', '10:30'), '');
  });

  test('bagDocketMutationBody sends bag_code for BAG prefix', () {
    final body = OutboundApiParams.bagDocketMutationBody(
      bagRef: 'BAG20260518152744831',
      docketNo: '825411779084407',
      branchId: '75',
      userId: '148',
    );
    expect(body['bag_code'], 'BAG20260518152744831');
    expect(body['docket_no'], '825411779084407');
    expect(body.containsKey('bag_id'), isFalse);
  });
}
