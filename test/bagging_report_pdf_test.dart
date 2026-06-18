import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/bagging_report_pdf_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds bagging challan PDF bytes from live API shape', () async {
    const sample = {
      'id': '200',
      'bag_code': 'BAG20260518152744831',
      'metal_seal_no': 'MSeal825411779084407',
      'origin_branch_name': 'KOLKATTA',
      'destination_city_name': 'Puttur',
      'created_by_name': 'SURAJ BAIT',
      'items': [
        {
          'shipment_id': '825411779084407',
          'sender_name': 'prajakta rajeshirke',
          'receiver_name': 'receiver_version',
          'destination_city': 'Mumbai',
          'total_weight': '11.00',
          'no_of_package': '1',
        },
      ],
    };

    final report = BaggingReport.fromJson(sample);
    final doc = BaggingReportPdfGenerator.buildDocument(
      report: report,
      createdByDisplay: report.createdByLabel('Fallback User'),
      printDate: DateTime(2026, 6, 18, 19, 9),
    );
    final bytes = await doc.save();
    expect(bytes.length, greaterThan(500));
    expect(
      BaggingReportPdfGenerator.formatPrintDate(
        DateTime(2026, 6, 18, 19, 9),
      ),
      contains('Jun-2026'),
    );
  });
}
