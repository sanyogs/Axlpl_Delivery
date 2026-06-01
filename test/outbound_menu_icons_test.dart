import 'package:axlpl_delivery/app/modules/outbound_common/outbound_menu_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboundMenuIcons', () {
    test('each pipeline step has a distinct asset path', () {
      const paths = [
        OutboundMenuIcons.home,
        OutboundMenuIcons.hubScan,
        OutboundMenuIcons.bagging,
        OutboundMenuIcons.manifest,
        OutboundMenuIcons.linehaul,
        OutboundMenuIcons.sectorPickup,
      ];
      expect(paths.toSet().length, paths.length);
      for (final path in paths) {
        expect(path, startsWith('assets/'));
        expect(path, endsWith('.png'));
      }
    });
  });
}
