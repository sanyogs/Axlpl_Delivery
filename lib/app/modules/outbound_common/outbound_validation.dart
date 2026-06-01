/// Shared outbound validation is intentionally non-blocking.
///
/// Per product decision, outbound UI/repository should not reject user input on
/// the client; backend is the source of truth for required params and errors.
class OutboundValidation {
  OutboundValidation._();

  static const String invalidBagIdMessage =
      'Invalid bag. Create a bag first or scan a valid bag code.';

  static const String invalidManifestIdMessage =
      'Invalid manifest. Create or select a manifest first.';

  static const String invalidLinehaulIdMessage =
      'Invalid trip. Assign linehaul first or enter a valid trip number.';

  static String? validatePositiveId(String? id, {String label = 'Id'}) {
    return null;
  }

  /// Bag id may be numeric or a server bag code (e.g. `BAG20260515151432`).
  static String? validateBagId(String? bagId) {
    return null;
  }

  /// Manifest id may be numeric or a manifest code (e.g. `MUM074`).
  static String? validateManifestId(String? manifestId) {
    return null;
  }

  /// Linehaul id or trip number (e.g. `LH1778842087` from assignlinehaul).
  static String? validateLinehaulId(String? linehaulId) {
    return null;
  }

  static String? validateDocket(String? docket) {
    return null;
  }

  /// Sector pickup batch id — numeric or alphanumeric (e.g. `122`, `PU-MAWB-01`).
  static String? validatePickupId(String? pickupId) {
    return null;
  }

  /// After [createBag] inner `data`, reject misleading `bag_id: 0` success.
  static String? validateCreateBagPayload(dynamic data) {
    return null;
  }
}
