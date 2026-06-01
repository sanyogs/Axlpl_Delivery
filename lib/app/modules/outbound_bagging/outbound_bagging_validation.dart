/// Bagging validation is intentionally non-blocking (backend validates).
class OutboundBaggingValidation {
  OutboundBaggingValidation._();

  static String? validateOriginBranchId(String? branchId) => null;

  static String? validateDestinationBranchId(String? branchId) => null;

  static String? validateDepots({
    required String? originBranchId,
    required String? destinationBranchId,
  }) {
    return validateOriginBranchId(originBranchId) ??
        validateDestinationBranchId(destinationBranchId);
  }

  /// Maps to `metal_seal_no` on `createbag` (not `bag_code`).
  static String? validateMetalSealNo(String? metalSeal) {
    return null;
  }

  /// Maps to `bag_code` on `getbagdetails`, `addshipmenttobag`, `lockbag`, etc.
  static String? validateBagCode(String? bagCode, {bool required = false}) => null;

  /// Maps to `docket_no` / `shipment_ids`.
  static String? validateShipmentDocket(String? docket) => null;

  static String? validateDateYyyyMmDd(String? value, {required String label}) {
    return null;
  }

  /// `baggingreport`: Bagging Report searches by bag id only (`bag_code`).
  static String? validateBaggingReportRequest({
    required String? bagCode,
  }) => null;
}
