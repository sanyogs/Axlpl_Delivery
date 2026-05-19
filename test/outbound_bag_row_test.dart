import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses live listbags array row', () {
    const sample = {
      'id': '184',
      'bag_code': 'BAG20260515222002',
      'metal_seal_no': 'VAL150526RPR',
      'origin_branch_id': '75',
      'destination_sector_id': '53',
      'created_by': null,
      'created_at': '2026-05-15 22:20:02',
      'updated_at': null,
    };

    final row = OutboundBagRow.fromJson(sample);
    expect(row.id, '184');
    expect(row.bagCode, 'BAG20260515222002');
    expect(row.metalSealNo, 'VAL150526RPR');
    expect(row.originBranchId, '75');
    expect(row.destinationSectorId, '53');
    expect(row.createdBy, isNull);
    expect(row.asMap['bag_code'], 'BAG20260515222002');
  });
}
