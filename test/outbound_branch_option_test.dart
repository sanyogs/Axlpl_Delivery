import 'package:axlpl_delivery/app/data/models/outbound/outbound_branch_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboundBranchOption', () {
    test('parses branch_id and branch_name', () {
      final rows = OutboundBranchOption.listFromDynamic([
        {'branch_id': '27', 'branch_name': 'Delhi'},
        {'branch_id': '75', 'branch_name': 'Chennai'},
      ]);
      expect(rows.length, 2);
      expect(rows.map((e) => e.id).toList(), containsAll(['27', '75']));
      expect(rows.singleWhere((e) => e.id == '27').label, 'Delhi');
    });

    test('dedupes by id', () {
      final rows = OutboundBranchOption.listFromDynamic([
        {'id': '5', 'name': 'Mumbai'},
        {'branch_id': '5', 'branch_name': 'Mumbai Hub'},
      ]);
      expect(rows.length, 1);
      expect(rows.single.label, 'Mumbai');
    });

    test('fromMessenger uses name when present', () {
      final o = OutboundBranchOption.fromMessenger(
        branchId: '2',
        branchName: 'Home branch',
      );
      expect(o?.label, 'Home branch');
    });
  });
}
