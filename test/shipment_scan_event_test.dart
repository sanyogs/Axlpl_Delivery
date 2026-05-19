import 'package:axlpl_delivery/app/data/models/outbound/shipment_scan_event_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses live getshipmentscanhistory array', () {
    const sample = [
      {
        'id': '1952575',
        's_id': '558751776258671',
        'status': 'Hub In',
        'is_exception': '0',
        'branch_id': '73',
        'created_by': '1',
        'u_type': null,
        'remark': '',
        'created_date': '2026-05-18 18:19:15',
        'modified_date': '2026-05-18 18:19:15',
        'sequence_no': '0',
        'is_negative': '0',
        'negative_remark': null,
        'receiver_name': null,
      },
      {
        'id': '1867757',
        's_id': '558751776258671',
        'status': 'Approved',
        'is_exception': '0',
        'branch_id': null,
        'created_by': '81',
        'remark': '',
        'created_date': '2026-04-15 18:41:11',
        'modified_date': '2026-04-15 18:41:11',
        'sequence_no': '2',
        'is_negative': '0',
      },
    ];

    final rows = ShipmentScanEvent.listFromDynamic(sample);
    expect(rows, hasLength(2));
    expect(rows.first.shipmentId, '558751776258671');
    expect(rows.first.status, 'Hub In');
    expect(rows.first.branchId, '73');
    expect(rows.first.isException, isFalse);
    expect(rows.first.createdBy, '1');
    expect(rows[1].branchId, isNull);
    expect(rows[1].sequenceNo, '2');
  });
}
