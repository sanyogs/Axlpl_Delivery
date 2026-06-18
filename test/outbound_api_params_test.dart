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

  test('updateLinehaulStatusBody uses trip_no for LH refs (Postman)', () {
    final body = OutboundApiParams.updateLinehaulStatusBody(
      linehaulRef: 'LH1779101374',
      status: 'ARRIVED',
      userId: '148',
      branchId: '75',
    );
    expect(body.containsKey('linehaul_id'), isFalse);
    expect(body['trip_no'], 'LH1779101374');
    expect(body['status'], 'ARRIVED');
  });

  test('updateLinehaulStatusBody uses linehaul_id for numeric refs', () {
    final body = OutboundApiParams.updateLinehaulStatusBody(
      linehaulRef: '129',
      status: 'ARRIVED',
      userId: '148',
      branchId: '75',
    );
    expect(body['linehaul_id'], '129');
    expect(body.containsKey('trip_no'), isFalse);
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

  test('editLinehaulBody mirrors LH ref as trip_no', () {
    final body = OutboundApiParams.editLinehaulBody(
      linehaulId: 'LH1778841961',
      vehicleNo: 'UP78AB1234',
    );
    expect(body['linehaul_id'], 'LH1778841961');
    expect(body['trip_no'], 'LH1778841961');
    expect(body['vehicle_no'], 'UP78AB1234');
  });

  test('createManifestBody matches Sarvesh — no transport_mode for Surface', () {
    final body = OutboundApiParams.createManifestBody(
      bagCodesCsv: 'BAG20260518152744831',
      originBranchId: '37',
      destinationBranchId: '75',
      userId: '1',
      transportMode: 'Surface',
    );
    expect(body.containsKey('transport_mode'), isFalse);
    expect(body['bag_codes'], 'BAG20260518152744831');
    expect(body['origin_branch_id'], '37');
    expect(body['destination_branch_id'], '75');
    expect(body['user_id'], '1');
  });

  test('createManifestBody includes transport_mode for Airway only', () {
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

  test('baggingReportQuery matches Sarvesh curl params', () {
    final q = OutboundApiParams.baggingReportQuery(
      bagCode: 'BAG20260518152744831',
      startDate: '2026-03-01',
      endDate: '2026-05-18',
    );
    expect(q['bag_code'], 'BAG20260518152744831');
    expect(q['start_date'], '2026-03-01');
    expect(q['end_date'], '2026-05-18');
  });

  test('manifestReportQuery uses manifest_no', () {
    final q = OutboundApiParams.manifestReportQuery(
      manifestNo: 'MUM094',
      startDate: '2026-05-01',
      endDate: '2026-05-18',
    );
    expect(q['manifest_no'], 'MUM094');
    expect(q['start_date'], '2026-05-01');
    expect(q['end_date'], '2026-05-18');
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
