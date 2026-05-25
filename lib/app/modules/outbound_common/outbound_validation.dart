import 'package:axlpl_delivery/app/data/models/outbound/outbound_mutation_result.dart';

/// Shared validation for outbound ids and mutation payloads.
class OutboundValidation {
  OutboundValidation._();

  static const String invalidBagIdMessage =
      'Invalid bag. Create a bag first or scan a valid bag code.';

  static const String invalidManifestIdMessage =
      'Invalid manifest. Create or select a manifest first.';

  static const String invalidLinehaulIdMessage =
      'Invalid trip. Assign linehaul first or enter a valid trip number.';

  static String? validatePositiveId(String? id, {String label = 'Id'}) {
    final s = id?.trim() ?? '';
    if (s.isEmpty) return '$label is required';
    final n = int.tryParse(s);
    if (n == null || n <= 0) return '$label must be a positive number';
    return null;
  }

  /// Bag id may be numeric or a server bag code (e.g. `BAG20260515151432`).
  static String? validateBagId(String? bagId) {
    final s = bagId?.trim() ?? '';
    if (s.isEmpty) return 'Bag code is required';
    if (s == '0') return invalidBagIdMessage;
    return null;
  }

  /// Manifest id may be numeric or a manifest code (e.g. `MUM074`).
  static String? validateManifestId(String? manifestId) {
    final s = manifestId?.trim() ?? '';
    if (s.isEmpty) return 'Manifest number is required';
    if (s == '0') return invalidManifestIdMessage;
    return null;
  }

  /// Linehaul id or trip number (e.g. `LH1778842087` from assignlinehaul).
  static String? validateLinehaulId(String? linehaulId) {
    final s = linehaulId?.trim() ?? '';
    if (s.isEmpty) return 'Trip number is required';
    if (s == '0') return invalidLinehaulIdMessage;
    return null;
  }

  static String? validateDocket(String? docket) {
    final s = docket?.trim() ?? '';
    if (s.isEmpty) return 'Docket number is required';
    return null;
  }

  /// After [createBag] inner `data`, reject misleading `bag_id: 0` success.
  static String? validateCreateBagPayload(dynamic data) {
    final result = OutboundMutationResult.fromDynamic(data);
    if (result.hasInvalidBagId) {
      if (validateBagId(result.bagCode) == null) {
        return null;
      }
      return 'Bag could not be created. Check depot selection and try again.';
    }
    if (validateBagId(result.bagId) != null && validateBagId(result.bagCode) != null) {
      return invalidBagIdMessage;
    }
    return null;
  }
}
