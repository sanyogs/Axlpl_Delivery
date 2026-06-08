import 'package:axlpl_delivery/app/data/models/outbound/outbound_bag_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses listbags success envelope via items wrapper', () {
    final rows = OutboundBagRow.listFromDynamic({
      'items': [
        {
          'id': '368',
          'bag_code': 'BAG20260608162751318',
          'metal_seal_no': 'bag123456789',
          'origin_branch_id': '27',
          'destination_sector_id': '39',
        },
      ],
      '__server_message': 'Bags retrieved successfully',
    });

    expect(rows, hasLength(1));
    expect(rows.first.bagCode, 'BAG20260608162751318');
    expect(rows.first.destinationSectorId, '39');
  });

  test('parses raw listbags array', () {
    final rows = OutboundBagRow.listFromDynamic([
      {
        'id': '299',
        'bag_code': 'BAG20260528211446',
        'origin_branch_id': '27',
        'destination_sector_id': '59',
      },
    ]);

    expect(rows, hasLength(1));
    expect(rows.first.id, '299');
  });
}
