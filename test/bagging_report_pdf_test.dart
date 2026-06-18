import 'package:axlpl_delivery/app/data/models/outbound/bagging_report_model.dart';
import 'package:axlpl_delivery/app/modules/outbound_bagging/bagging_report_pdf_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds bagging challan PDF bytes from live API shape', () async {
    const sample = {
      'id': '458',
      'bag_code': 'BAG20260618171826757',
      'metal_seal_no': 'bag9998979695',
      'origin_branch_name': 'MUMBAI',
      'destination_city_name': 'Mumbai',
      'created_by_name': 'SURAJ BAIT',
      'gst_no': '27AAQCA4042D1ZU',
      'items': [
        {
          'shipment_id': '9998979695',
          'sender_name': 'version next technology',
          'receiver_name': 'Version Next',
          'destination_city': 'Mumbai',
          'total_weight': '11.00',
          'no_of_package': '1',
        },
      ],
    };

    final report = BaggingReport.fromJson(sample);
    expect(report.gstNo, '27AAQCA4042D1ZU');
    expect(
      report.companyHeaderLine,
      'GSTN: 27AAQCA4042D1ZU | Website: www.axlpl.com | Email: info@axlpl.com',
    );
    final doc = BaggingReportPdfGenerator.buildDocument(
      report: report,
      createdByDisplay: report.createdByLabel('Fallback User'),
      printDate: DateTime(2026, 6, 18, 19, 22),
    );
    final bytes = await doc.save();
    expect(bytes.length, greaterThan(500));
    expect(
      BaggingReportPdfGenerator.formatPrintDate(
        DateTime(2026, 6, 18, 19, 22),
      ),
      contains('Jun-2026'),
    );
  });

  test('gstDisplay falls back when gst_no missing', () {
    const sample = {'bag_code': 'BAGTEST'};
    final report = BaggingReport.fromJson(sample);
    expect(report.gstDisplay, BaggingReport.defaultGstNo);
  });
}
