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
    if (looksLikeManifestCode(ref)) {
      return [
        {'manifest_code': ref},
        {'code': ref},
      ];
    }
    return [
      {'manifest_id': ref},
      {'manifest_code': ref},
    ];
  }

  static List<Map<String, String>> linehaulDetailQueries(String linehaulRef) {
    final ref = linehaulRef.trim();
    if (looksLikeTripNo(ref)) {
      return [
        {'trip_no': ref},
        {'mawb_no': ref},
        {'linehaul_id': ref},
      ];
    }
    return [
      {'mawb_no': ref},
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
    if (int.tryParse(first) != null) {
      return {'manifest_ids': ids};
    }
    return {'manifest_codes': ids, 'manifest_ids': ids};
  }

  /// POST `createmanifest` — verified multipart: `bag_codes`, branches, `user_id` only.
  static Map<String, String> createManifestBody({
    required String bagCodesCsv,
    required String originBranchId,
    required String destinationBranchId,
    required String userId,
  }) {
    return {
      ...createManifestBagFields(bagCodesCsv),
      'origin_branch_id': originBranchId.trim(),
      'destination_branch_id': destinationBranchId.trim(),
      'user_id': userId,
    };
  }

  /// GET `baggingreport` — Sarvesh: `bag_code` + `start_date` + `end_date`.
  static Map<String, String> baggingReportQuery({
    required String bagCode,
    required String startDate,
    required String endDate,
  }) =>
      {
        'bag_code': bagCode.trim(),
        'start_date': startDate.trim(),
        'end_date': endDate.trim(),
      };

  /// GET `manifestreport` — Sarvesh: `manifest_no` + date range.
  static Map<String, String> manifestReportQuery({
    required String manifestNo,
    required String startDate,
    required String endDate,
  }) =>
      {
        'manifest_no': manifestNo.trim(),
        'start_date': startDate.trim(),
        'end_date': endDate.trim(),
      };

  static String formatReportDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Default report window for bagging/manifest report screens.
  static Map<String, String> defaultReportDateRange({int days = 90}) {
    final now = DateTime.now();
    return {
      'start_date': formatReportDate(now.subtract(Duration(days: days))),
      'end_date': formatReportDate(now),
    };
  }

  /// Combine date + time for `editlinehaul` / linehaul booking POST fields.
  static String combineDateTime(String date, String time) {
    final d = date.trim();
    if (d.isEmpty) return '';
    final t = time.trim();
    if (t.isEmpty) return '$d 00:00:00';
    if (t.length == 5) return '$d $t:00';
    return '$d $t';
  }

  /// First non-empty combined datetime (e.g. booking departure vs AWB datetime).
  static String firstCombinedDateTime(
    String date1,
    String time1,
    String date2,
    String time2,
  ) {
    final a = combineDateTime(date1, time1);
    if (a.isNotEmpty) return a;
    return combineDateTime(date2, time2);
  }

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

  /// POST `updatelinehaulstatus` — Postman sends `trip_no` for LH refs; numeric id otherwise.
  static Map<String, String> updateLinehaulStatusBody({
    required String linehaulRef,
    required String status,
    required String userId,
    required String branchId,
  }) {
    final ref = linehaulRef.trim();
    final body = <String, String>{
      'status': status.trim(),
      'user_id': userId,
      'branch_id': branchId.trim(),
    };
    if (looksLikeTripNo(ref)) {
      body['trip_no'] = ref;
    } else {
      body['linehaul_id'] = ref;
    }
    return body;
  }

  /// POST `editlinehaul` — urlencoded; `linehaul_id` required.
  static Map<String, String> editLinehaulBody({
    required String linehaulId,
    String? vehicleNo,
    String? driverName,
    String? driverMobile,
    String? mawbNo,
    String? tripNo,
    String? departureTime,
    String? arrivalTime,
    String? remarks,
    String? flightNo,
    String? airline,
    String? ewayBill,
    String? transportType,
  }) {
    final ref = linehaulId.trim();
    final body = <String, String>{'linehaul_id': ref};
    void add(String key, String? value) {
      final t = value?.trim();
      if (t != null && t.isNotEmpty) body[key] = t;
    }

    add('vehicle_no', vehicleNo);
    add('driver_name', driverName);
    add('driver_mobile', driverMobile);
    add('mawb_no', mawbNo);
    if (looksLikeTripNo(ref)) {
      body['trip_no'] = ref;
    } else {
      add('trip_no', tripNo);
    }
    add('departure_time', departureTime);
    add('arrival_time', arrivalTime);
    add('remarks', remarks);
    add('flight_no', flightNo);
    add('airline', airline);
    add('eway_bill', ewayBill);
    add('transport_type', transportType);
    return body;
  }

  /// POST `deletelinehaul` — urlencoded; send the available linehaul refs.
  static Map<String, String> deleteLinehaulBody({
    required String linehaulId,
    String? tripNo,
    String? mawbNo,
  }) {
    final ref = linehaulId.trim();
    final body = <String, String>{'linehaul_id': ref};

    final trip = tripNo?.trim();
    if (trip != null && trip.isNotEmpty) {
      body['trip_no'] = trip;
    } else if (looksLikeTripNo(ref)) {
      body['trip_no'] = ref;
    }

    final mawb = mawbNo?.trim();
    if (mawb != null && mawb.isNotEmpty) {
      body['mawb_no'] = mawb;
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
