/// Admin-aligned field labels for outbound screens (not internal API param names).
class OutboundLabels {
  OutboundLabels._();

  static const docketNo = 'Docket no';
  static const shipmentNo = 'Shipment no (docket)';
  static const originDepot = 'Origin depot';
  static const destinationDepot = 'Destination depot';
  static const branchHub = 'Branch / Hub';
  static const bagCode = 'Bag code';
  static const workingBagCode = 'Bag code (scan or pick from list)';
  static const bagCodesCsv = 'Bag codes (comma-separated)';
  static const manifestCode = 'Manifest code';
  static const manifestCodesCsv = 'Manifest codes (comma-separated)';
  static const tripNo = 'Trip no / linehaul ref';
  static const mawbNo = 'MAWB no';
  static const pickupId = 'Pickup id';
  static const scanStatus = 'Scan status';
  static const hubScanStatus = 'Hub scan status';
  static const vehicleNo = 'Vehicle no';
  static const driverName = 'Driver name';
  static const linehaulFilterStatus = 'Linehaul status filter';
  static const newLinehaulStatus = 'New linehaul status';
  static const remarks = 'Remarks';
  static const logLimit = 'Log limit';
  static const reportStart = 'Report start date';
  static const reportEnd = 'Report end date';
  static const newBagCode = 'New bag code (rebag)';
  /// Scanned once; API expects both `metal_seal_no` and `bag_code`.
  static const metalSeal = 'Metal seal no (bag code)';
  /// Comma-separated docket / shipment ids — required for `createbag`.
  static const shipmentIdsForCreateBag =
      'Shipment id(s) for bagging (comma-separated)';
}
