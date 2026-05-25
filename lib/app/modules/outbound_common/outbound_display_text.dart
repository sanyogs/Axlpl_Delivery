/// Turns API / JSON keys into readable UI labels (outbound only).
abstract final class OutboundDisplayText {
  OutboundDisplayText._();

  static const _knownKeys = <String, String>{
    'bag_code': 'Bag code',
    'bag_id': 'Bag id',
    'bag_codes': 'Bag codes',
    'bag_ids': 'Bag ids',
    'metal_seal_no': 'Metal seal',
    'shipment_id': 'Shipment',
    'shipment_ids': 'Shipment ids',
    'shipment_no': 'Shipment no',
    'docket_no': 'Docket no',
    'manifest_no': 'Manifest number',
    'manifest_code': 'Manifest number',
    'manifest_codes': 'Manifest numbers',
    'manifest_id': 'Manifest id',
    'manifest_ids': 'Manifest ids',
    'origin_branch_id': 'Origin depot',
    'origin_branch': 'Origin depot',
    'destination_branch_id': 'Destination depot',
    'destination_branch': 'Destination depot',
    'destination_sector_id': 'Destination sector',
    'branch_id': 'Branch',
    'hub_id': 'Hub',
    'trip_no': 'Trip no',
    'linehaul_id': 'Linehaul id',
    'vehicle_no': 'Vehicle no',
    'driver_name': 'Driver name',
    'mawb_no': 'MAWB no',
    'pickup_id': 'Pickup id',
    'created_at': 'Created',
    'updated_at': 'Updated',
    'scanned_at': 'Scanned at',
    'scan_type': 'Scan type',
    'gross_weight': 'Gross weight',
    'volumetric_weight': 'Volumetric weight',
    'no_of_package': 'Packages',
    'receiver_name': 'Receiver',
    'sender_name': 'Sender',
    'destination_city': 'Destination city',
    'invoice_no': 'Invoice no',
    'box_no': 'Box no',
  };

  /// `bag_code` → `Bag Code`, with overrides for common outbound keys.
  static String labelForKey(String key) {
    final k = key.trim();
    if (k.isEmpty) return k;
    final lower = k.toLowerCase();
    final known = _knownKeys[lower];
    if (known != null) return known;
    return _titleCase(_humanizeToken(k));
  }

  static String _humanizeToken(String raw) {
    var s = raw.replaceAll(RegExp(r'[_\-\.]+'), ' ').trim();
    s = s.replaceAll(RegExp(r'([a-z])([A-Z])'), r'$1 $2');
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String _titleCase(String words) {
    if (words.isEmpty) return words;
    return words
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map(
          (w) => w.length == 1
              ? w.toUpperCase()
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
