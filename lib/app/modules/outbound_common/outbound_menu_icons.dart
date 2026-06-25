import 'package:flutter/material.dart';

/// Icons for outbound navigation (home tile + outbound process menu).
///
/// Vector [IconData] keeps all tiles the same style and resolution on any DPI.
abstract final class OutboundMenuIcons {
  OutboundMenuIcons._();

  /// Home dashboard entry — outbound logistics pipeline.
  static const IconData home = Icons.warehouse_outlined;

  /// Module A — barcode scan at hub.
  static const IconData hubScan = Icons.qr_code_scanner_outlined;

  /// Module B — pack shipments into bags.
  static const IconData bagging = Icons.inventory_2_outlined;

  /// Module C — manifest creation and listing.
  static const IconData manifest = Icons.assignment_outlined;

  /// Module D — linehaul assignment and tracking.
  static const IconData linehaul = Icons.local_shipping_outlined;

  /// Module E — sector pickup scans.
  static const IconData sectorPickup = Icons.pin_drop_outlined;

  /// Sector pickup status report (`pickupreport`).
  static const IconData sectorPickupReport = Icons.assessment_outlined;
}
