import 'package:axlpl_delivery/app/data/models/outbound/outbound_airline_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses getairlines response rows', () {
    final rows = OutboundAirlineOption.listFromDynamic([
      {
        'id': 2,
        'code': 'AI',
        'prefix': '98',
        'airline_name': 'Air India',
      },
      {
        'id': 3,
        'code': 'IGO',
        'prefix': '312',
        'airline_name': 'IndiGo CarGo',
      },
    ]);

    expect(rows.map((e) => e.id), ['2', '3']);
    expect(rows.first.name, 'Air India');
    expect(rows.first.label, 'Air India (AI)');
    expect(rows.first.prefix, '98');
  });
}
