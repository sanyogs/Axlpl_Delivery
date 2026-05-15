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
    String idKey = 'bag_id',
  }) {
    final ref = bagRef.trim();
    final body = <String, String>{idKey: ref};
    if (looksLikeBagCode(ref)) {
      body['bag_code'] = ref;
      if (idKey == 'new_bag_id') {
        body['new_bag_code'] = ref;
      }
    }
    return body;
  }

  static List<Map<String, String>> bagDetailQueries(String bagRef) {
    final ref = bagRef.trim();
    return [
      {'bag_id': ref},
      if (looksLikeBagCode(ref)) ...[
        {'bag_code': ref},
        {'code': ref},
      ],
    ];
  }

  static List<Map<String, String>> manifestDetailQueries(String manifestRef) {
    final ref = manifestRef.trim();
    return [
      {'manifest_id': ref},
      if (looksLikeManifestCode(ref)) ...[
        {'manifest_code': ref},
        {'code': ref},
      ],
    ];
  }

  static List<Map<String, String>> linehaulDetailQueries(String linehaulRef) {
    final ref = linehaulRef.trim();
    return [
      {'linehaul_id': ref},
      if (looksLikeTripNo(ref)) {'trip_no': ref},
    ];
  }

  static Map<String, String> createManifestBagFields(String bagIdsCsv) {
    final ids = bagIdsCsv.trim();
    final body = <String, String>{'bag_ids': ids};
    if (looksLikeBagCode(ids.split(',').first.trim())) {
      body['bag_codes'] = ids;
    }
    return body;
  }
}
