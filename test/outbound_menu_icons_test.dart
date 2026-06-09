import 'package:axlpl_delivery/app/modules/outbound_common/outbound_menu_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboundMenuIcons', () {
    test('each pipeline step has a distinct icon', () {
      const icons = [
        OutboundMenuIcons.home,
        OutboundMenuIcons.hubScan,
        OutboundMenuIcons.bagging,
        OutboundMenuIcons.manifest,
        OutboundMenuIcons.linehaul,
        OutboundMenuIcons.sectorPickup,
      ];
      expect(icons.toSet().length, icons.length);
      for (final icon in icons) {
        expect(icon, isA<IconData>());
      }
    });
  });
}
