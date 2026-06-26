import 'package:axlpl_delivery/utils/assets.dart';

/// Colorful asset icons for outbound navigation (home tile + outbound menu).
///
/// Matches the flat PNG style used by Pickups, Delivery, Add Shipment, etc.
abstract final class OutboundMenuIcons {
  OutboundMenuIcons._();

  /// Home dashboard entry — outbound logistics pipeline.
  static const String home = outboundHomeIcon;

  /// Module A — barcode scan at hub.
  static const String hubScan = outboundHubScanIcon;

  /// Module B — pack shipments into bags.
  static const String bagging = outboundBaggingIcon;

  /// Module C — manifest creation and listing.
  static const String manifest = outboundManifestIcon;

  /// Module D — linehaul assignment and tracking.
  static const String linehaul = outboundLinehaulIcon;

  /// Module E — sector pickup scans.
  static const String sectorPickup = outboundSectorPickupIcon;

  /// Sector pickup status report (`pickupreport`).
  static const String sectorPickupReport = outboundSectorPickupReportIcon;
}
