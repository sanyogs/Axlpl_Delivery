import 'package:axlpl_delivery/app/data/models/tracking_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses invoice_files from track API shipment details', () {
    final details = ShipmentDetails.fromJson({
      'shipment_id': '6968676665',
      'invoice_path':
          'https://my.axlpl.com/admin/template/assets/images/invoice_file/',
      'invoice_file': '',
      'invoice_files': [
        {
          'id': '3',
          'file_name': '6968676665_6a3d18523329d.jpg',
          'original_name': 'scaled_508.jpg',
          'file_url':
              'https://my.axlpl.com/admin/template/assets/images/invoice_file/6968676665_6a3d18523329d.jpg',
        },
        {
          'file_name': '6968676665_6a3d185234a3a.png',
          'original_name': 'scaled_502.png',
          'file_url':
              'https://my.axlpl.com/admin/template/assets/images/invoice_file/6968676665_6a3d185234a3a.png',
        },
      ],
    });

    expect(details.invoiceFiles, hasLength(2));
    expect(details.invoiceFiles!.first.id, '3');
    expect(details.invoiceFiles!.first.canDelete, isTrue);
    expect(
      details.invoiceFiles!.first.resolvedUrl(details.invoicePath),
      contains('6968676665_6a3d18523329d.jpg'),
    );
  });
}
