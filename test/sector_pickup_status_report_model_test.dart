import 'package:axlpl_delivery/app/data/models/outbound/sector_pickup_status_report_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses paginated pickupreport payload from admin API', () {
    const payload = {
      'total': 2633,
      'page': 3,
      'limit': 50,
      'total_pages': 53,
      'sector_pickup_done': 2484,
      'sector_pickup_pending': 149,
      'data': [
        {
          'shipment_id': '745131782222565',
          'shipment_no': '26-27/28',
          'origin': 'Jaipur',
          'destination': 'Mumbai',
          'linehaul_no': '312-70187515',
          'linehaul_date': '2026-06-24 04:40:00',
          'sector_pickup_no': '403',
          'pickup_date': '2026-06-24',
          'current_status': 'Delivered',
          'sector_pickup_status': 'Sector Pickup Done',
        },
      ],
    };

    final page = SectorPickupStatusReportPage.fromDynamic(payload);
    expect(page.total, 2633);
    expect(page.page, 3);
    expect(page.limit, 50);
    expect(page.totalPages, 53);
    expect(page.pickupDone, 2484);
    expect(page.pickupPending, 149);
    expect(page.rows, hasLength(1));
    expect(page.rows.first.displayShipmentNo, '26-27/28');
    expect(page.rows.first.origin, 'Jaipur');
    expect(page.rows.first.pickupStatusShort, 'DONE');
  });
}
