/// Builds query/body field maps when the server accepts codes vs numeric ids.
class OutboundApiParams {
  OutboundApiParams._();

  static bool looksLikeBagCode(String value) {
    final s = value.trim().toUpperCase();
    return s.startsWith('BAG') && s.length > 3;
  }

  static bool looksLikeManifestCode(String value) {
    final s = value.trim();
    if (s.isEmpty) return false;
    if (int.tryParse(s) != null) return false;
    return RegExp(r'^[A-Za-z]{2,}').hasMatch(s);
  }

  static bool looksLikeTripNo(String value) {
    final s = value.trim().toUpperCase();
    return s.startsWith('LH') && s.length > 2;
  }

  /// POST bodies for bagging: send both keys when value is a bag code string.
  static Map<String, String> bagReferenceBody(
    String bagRef, {
    String idKey = 'bag_code',
  }) {
    final ref = bagRef.trim();
    if (idKey == 'new_bag_code' || idKey == 'new_bag_id') {
      return {'new_bag_code': ref};
    }
    final body = <String, String>{'bag_code': ref};
    if (!looksLikeBagCode(ref)) {
      body['bag_id'] = ref;
    }
    return body;
  }

  static List<Map<String, String>> bagDetailQueries(String bagRef) {
    final ref = bagRef.trim();
    return [
      if (looksLikeBagCode(ref)) {'bag_code': ref},
      {'bag_id': ref},
      if (looksLikeBagCode(ref)) {'code': ref},
    ];
  }

  static List<Map<String, String>> manifestDetailQueries(String manifestRef) {
    final ref = manifestRef.trim();
    return [
      if (looksLikeManifestCode(ref)) {'manifest_code': ref},
      {'manifest_id': ref},
      if (looksLikeManifestCode(ref)) {'code': ref},
    ];
  }

  static List<Map<String, String>> linehaulDetailQueries(String linehaulRef) {
    final ref = linehaulRef.trim();
    return [
      if (looksLikeTripNo(ref)) {'trip_no': ref},
      {'linehaul_id': ref},
    ];
  }

  /// Parses comma / whitespace separated docket or shipment ids.
  static List<String> parseShipmentIdsCsv(String raw) {
    return raw
        .split(RegExp(r'[,\s;]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String shipmentIdsCsv(List<String> ids) => ids.join(',');

  /// POST `createbag` — Postman: `origin_branch_id`, `destination_branch_id`, `user_id`,
  /// optional `bag_code`; production also requires `metal_seal_no` + `shipment_ids`.
  static Map<String, String> createBagBody({
    required String metalSealNo,
    required String shipmentIdsCsv,
    String? bagCode,
  }) {
    final body = <String, String>{
      'metal_seal_no': metalSealNo.trim(),
      'shipment_ids': shipmentIdsCsv.trim(),
    };
    final code = bagCode?.trim();
    if (code != null && code.isNotEmpty && looksLikeBagCode(code)) {
      body['bag_code'] = code;
    }
    return body;
  }

  static Map<String, String> createManifestBagFields(String bagIdsCsv) {
    final ids = bagIdsCsv.trim();
    final first = ids.split(',').first.trim();
    if (looksLikeBagCode(first)) {
      return {'bag_codes': ids};
    }
    return {'bag_ids': ids, 'bag_codes': ids};
  }

  static Map<String, String> assignLinehaulManifestFields(String manifestCsv) {
    final ids = manifestCsv.trim();
    final first = ids.split(',').first.trim();
    if (looksLikeManifestCode(first)) {
      return {'manifest_codes': ids};
    }
    return {'manifest_codes': ids, 'manifest_ids': ids};
  }

  /// POST `createmanifest` — verified: `bag_codes`, branches, `user_id`.
  static Map<String, String> createManifestBody({
    required String bagCodesCsv,
    required String originBranchId,
    required String destinationBranchId,
    required String userId,
  }) =>
      {
        ...createManifestBagFields(bagCodesCsv),
        'origin_branch_id': originBranchId.trim(),
        'destination_branch_id': destinationBranchId.trim(),
        'user_id': userId,
      };

  /// POST `assignlinehaul` — verified: `manifest_codes`, vehicle, driver, `user_id`.
  static Map<String, String> assignLinehaulBody({
    required String manifestCodesCsv,
    required String vehicleNo,
    required String driverName,
    required String userId,
  }) =>
      {
        ...assignLinehaulManifestFields(manifestCodesCsv),
        'vehicle_no': vehicleNo.trim(),
        'driver_name': driverName.trim(),
        'user_id': userId,
      };

  /// POST `updatelinehaulstatus` — send `linehaul_id` and `trip_no` when LH-prefixed.
  static Map<String, String> updateLinehaulStatusBody({
    required String linehaulRef,
    required String status,
    required String userId,
    required String branchId,
  }) {
    final ref = linehaulRef.trim();
    final body = <String, String>{
      'linehaul_id': ref,
      'status': status.trim(),
      'user_id': userId,
      'branch_id': branchId.trim(),
    };
    if (looksLikeTripNo(ref)) {
      body['trip_no'] = ref;
    }
    return body;
  }

  /// POST bagging mutations — `bag_code` (+ `bag_id` when not a BAG… code).
  static Map<String, String> bagMutationBody(
    String bagRef, {
    String idKey = 'bag_code',
  }) =>
      bagReferenceBody(bagRef, idKey: idKey);

  /// POST `addshipmenttobag` / `removeshipmentfrombag`.
  static Map<String, String> bagDocketMutationBody({
    required String bagRef,
    required String docketNo,
    required String branchId,
    required String userId,
  }) =>
      {
        ...bagReferenceBody(bagRef),
        'docket_no': docketNo.trim(),
        'branch_id': branchId.trim(),
        'user_id': userId,
      };

  /// POST `sectorpickupscan`.
  static Map<String, String> sectorPickupScanBody({
    required String pickupId,
    required String docketNo,
    required String status,
    required String remarks,
    required String userId,
    required String branchId,
  }) =>
      {
        'pickup_id': pickupId.trim(),
        'docket_no': docketNo.trim(),
        'status': status.trim(),
        'remarks': remarks.trim(),
        'user_id': userId,
        'branch_id': branchId.trim(),
      };

  /// POST `marknotpicked`.
  static Map<String, String> markNotPickedBody({
    required String pickupId,
    required String docketNo,
    required String remarks,
    required String userId,
    required String branchId,
  }) =>
      {
        'pickup_id': pickupId.trim(),
        'docket_no': docketNo.trim(),
        'remarks': remarks.trim(),
        'user_id': userId,
        'branch_id': branchId.trim(),
      };

  /// POST `addmissedshipment`.
  static Map<String, String> addMissedShipmentBody({
    required String pickupId,
    required String docketNo,
    required String remarks,
    String? userId,
    String? branchId,
  }) {
    final body = <String, String>{
      'pickup_id': pickupId.trim(),
      'docket_no': docketNo.trim(),
      'remarks': remarks.trim(),
    };
    final u = userId?.trim();
    final b = branchId?.trim();
    if (u != null && u.isNotEmpty) body['user_id'] = u;
    if (b != null && b.isNotEmpty) body['branch_id'] = b;
    return body;
  }
}
