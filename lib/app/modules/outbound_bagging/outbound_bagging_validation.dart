import 'package:axlpl_delivery/app/modules/outbound_common/outbound_api_params.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_validation.dart';

/// Validation for bagging UI fields → Postman / QA API parameters.
class OutboundBaggingValidation {
  OutboundBaggingValidation._();

  static String? validateOriginBranchId(String? branchId) {
    final s = branchId?.trim() ?? '';
    if (s.isEmpty) return 'Origin depot is required';
    return null;
  }

  static String? validateDestinationBranchId(String? branchId) {
    final s = branchId?.trim() ?? '';
    if (s.isEmpty) return 'Destination depot is required';
    return null;
  }

  static String? validateDepots({
    required String? originBranchId,
    required String? destinationBranchId,
  }) {
    return validateOriginBranchId(originBranchId) ??
        validateDestinationBranchId(destinationBranchId);
  }

  /// Maps to `metal_seal_no` on `createbag` (not `bag_code`).
  static String? validateMetalSealNo(String? metalSeal) {
    final s = metalSeal?.trim() ?? '';
    if (s.isEmpty) return 'M/Bag No (metal seal) is required';
    if (OutboundApiParams.looksLikeBagCode(s)) {
      return 'Enter metal seal in M/Bag No — use Bag Code field for BAG… codes';
    }
    return null;
  }

  /// Maps to `bag_code` on `getbagdetails`, `addshipmenttobag`, `lockbag`, etc.
  static String? validateBagCode(String? bagCode, {bool required = false}) {
    final s = bagCode?.trim() ?? '';
    if (s.isEmpty) {
      return required ? 'Bag code is required' : null;
    }
    return OutboundValidation.validateBagId(s);
  }

  /// Maps to `docket_no` / `shipment_ids`.
  static String? validateShipmentDocket(String? docket) =>
      OutboundValidation.validateDocket(docket);

  static String? validateDateYyyyMmDd(String? value, {required String label}) {
    final s = value?.trim() ?? '';
    if (s.isEmpty) return '$label is required';
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return '$label must be YYYY-MM-DD';
    return null;
  }

  /// `baggingreport`: Postman needs dates; QA detail needs `bag_code`.
  static String? validateBaggingReportRequest({
    required String? bagCode,
    required String? startDate,
    required String? endDate,
  }) {
    final code = bagCode?.trim() ?? '';
    final start = startDate?.trim() ?? '';
    final end = endDate?.trim() ?? '';

    if (code.isNotEmpty) {
      return validateBagCode(code);
    }

    final startErr = validateDateYyyyMmDd(start, label: 'Start date');
    if (startErr != null) return startErr;
    final endErr = validateDateYyyyMmDd(end, label: 'End date');
    if (endErr != null) return endErr;

    final startDt = DateTime.parse(start);
    final endDt = DateTime.parse(end);
    if (endDt.isBefore(startDt)) {
      return 'End date must be on or after start date';
    }
    return null;
  }
}
