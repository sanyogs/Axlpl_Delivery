import 'package:axlpl_delivery/app/modules/outbound_common/outbound_menu_icons.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboundMenuIcons', () {
    test('each pipeline step has a distinct colorful asset icon', () {
      const icons = [
        OutboundMenuIcons.home,
        OutboundMenuIcons.hubScan,
        OutboundMenuIcons.bagging,
        OutboundMenuIcons.manifest,
        OutboundMenuIcons.linehaul,
        OutboundMenuIcons.sectorPickup,
        OutboundMenuIcons.sectorPickupReport,
      ];
      expect(icons.toSet().length, icons.length);
      for (final icon in icons) {
        expect(icon, startsWith('assets/outbound_'));
        expect(icon, endsWith('.png'));
      }
    });
  });
}
