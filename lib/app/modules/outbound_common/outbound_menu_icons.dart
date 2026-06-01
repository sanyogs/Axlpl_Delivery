import 'package:axlpl_delivery/utils/assets.dart';

/// Asset paths for outbound navigation (home tile + outbound process menu).
///
/// Each step in the pipeline has a distinct icon:
/// Hub scan → Bagging → Manifest → Linehaul → Sector pickup.
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
}
