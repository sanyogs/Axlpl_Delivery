import 'package:axlpl_delivery/app/data/models/outbound/outbound_linehaul_row_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('deleteRef falls back from numeric id to trip and airway refs', () {
    expect(
      const OutboundLinehaulRow(linehaulId: '129', tripNo: 'LH1').deleteRef,
      '129',
    );
    expect(const OutboundLinehaulRow(linehaulId: '0', tripNo: 'LH1').deleteRef,
        'LH1');
    expect(const OutboundLinehaulRow(mawbNo: 'AWB1').deleteRef, 'AWB1');
  });
}
