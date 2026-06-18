import 'package:axlpl_delivery/app/data/models/outbound/bag_detail_item_model.dart';
import 'package:axlpl_delivery/app/data/models/outbound/bagging_table_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses explicit mode override for saved bag detail rows', () {
    const item = BagDetailItem(
      shipmentId: '825411779084407',
      shipmentStatus: 'Shipment already delivered',
    );

    final row = BaggingTableRow.fromBagDetailItem(
      item,
      bagCode: 'BAG20260518152744831',
      destination: 'Mumbai',
      mode: 'Not Manifested',
    );

    expect(row.bagCode, 'BAG20260518152744831');
    expect(row.shipmentId, '825411779084407');
    expect(row.destination, 'Mumbai');
    expect(row.mode, 'Not Manifested');
    expect(row.saved, isTrue);
  });
}
