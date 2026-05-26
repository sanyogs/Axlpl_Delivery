/// User-facing labels for outbound screens (not API param names).
class OutboundLabels {
  OutboundLabels._();

  static const docketNo = 'Docket no';
  static const connoteNo = 'Connote no';
  static const scanDocketNo = 'Scan Docket No';
  static const scanType = 'Scan Type';
  static const clientCode = 'Client Code';
  static const noOfBox = 'No of Box';
  static const boxWeight = 'Box Weight';
  static const originPincode = 'Origin Pincode';
  static const destPincode = 'Dest. Pincode';
  static const destCity = 'Dest. City';
  static const receiverName = 'Receiver';
  static const shipmentNo = 'Shipment no';
  static const originDepot = 'Origin depot';
  static const destinationDepot = 'Destination depot';
  static const branchHub = 'Branch / hub';
  static const bagCode = 'Bag code';
  static const workingBagCode = 'Bag code';
  static const bagCodesCsv = 'Bag codes (comma separated)';
  static const manifestCode = 'Manifest number';
  static const manifestCodesCsv = 'Manifest numbers (comma separated)';
  static const listDepot = 'Depot';
  static const tripNo = 'Trip no';
  static const mawbNo = 'MAWB no';
  static const pickupId = 'Pickup id';
  static const scanStatus = 'Scan status';
  static const status = 'Status';
  static const hubScanStatus = 'Hub scan status';
  static const vehicleNo = 'Vehicle no';
  static const driverName = 'Driver name';
  static const linehaulFilterStatus = 'Filter by status';
  static const newLinehaulStatus = 'New status';
  static const remarks = 'Remarks';
  static const logLimit = 'Log limit';
  static const reportStart = 'Start date';
  static const reportEnd = 'End date';
  static const created = 'Created';
  static const updated = 'Updated';
  static const manifestStatus = 'Manifest status';
  static const shipmentCount = 'Shipment count';
  static const linehaulId = 'Linehaul id';
  static const manifestNumbers = 'Manifest numbers';
  static const newBagCode = 'New bag code';
  static const metalSeal = 'Metal seal no';
  static const shipmentIdsForCreateBag = 'Shipment nos (comma separated)';
  static const removeRebagDocket = 'Remove / rebag docket no';
  static const useScanDocketForBag = 'Copy docket';
  static const selectStatus = 'Select';

  // Section subtitles
  static const subtitleCreateBag =
      'Scan metal seal and add at least one shipment.';
  static const subtitleHubScan =
      'Scan connote, fetch details, then submit hub scan.';
  static const sectionDocketDetails = 'Docket Scan details';
  static const sectionScannedDockets = 'Scanned Docket Details';
  static const btnSave = 'Save';
  static const btnConfirm = 'Confirm';
  static const btnShowList = 'Show List';
  static const totalScanned = 'Total Scanned';
  static const totalParcels = 'Total Parcels';
  static const hubScanListTitle = 'Hub Scan List';
  static const hubScanHistory = 'Hub Scan History';
  static const btnPerformScan = 'Perform Scan';
  static const btnNewHubScan = 'New Hub Scan';
  static const colSlNo = '#';
  static const colShipmentDocket = 'SHIPMENT ID / DOCKET';
  static const colScanType = 'SCAN TYPE';
  static const colBranchHub = 'BRANCH / HUB';
  static const colScannedAt = 'SCANNED AT';
  static const colActions = 'ACTIONS';
  static const hubScanLogId = 'Log id';
  static const hubScanShipmentId = 'Shipment id';
  static const hubScanBoxNo = 'Box no';
  static const subtitleScanHistory = 'Look up events for a docket.';
  static const subtitleAssignLinehaul =
      'Assign manifests to a vehicle and driver.';
  static const subtitlePickupList = 'Tap a row to set pickup id.';
  static const subtitleManifestCreate =
      'Add sealed bags from origin to destination.';
  static const subtitleManifestOpen =
      'List by depot, tap a row, or enter manifest number.';
  static const subtitleManifestReport = 'Choose a date range.';

  // Short button labels
  static const btnShipmentInfo = 'Shipment info';
  static const btnScanHistory = 'History';
  static const btnListBags = 'List bags';
  static const btnBaggingReport = 'Report';
  static const btnLinehaulReport = 'Report';
  static const btnPickupReport = 'Report';
  static const btnRemoveShipment = 'Remove';
  static const btnBagDetails = 'Details';
  static const btnFullBagDetail = 'Full detail';
  static const btnLinehaulDetails = 'Details';
  static const btnFullLinehaulDetail = 'Full detail';
  static const btnMarkNotPicked = 'Not picked';
  static const btnAddMissed = 'Add missed';
  static const btnRebag = 'Rebag';
  static const btnViewDetails = 'Details';
  static const btnPrint = 'Print';
  static const btnRefreshLogs = 'Refresh logs';
  static const btnTapRowBag = 'Tap a row to use bag code';
}
