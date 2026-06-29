import 'package:axlpl_delivery/app/data/models/invoice_upload_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses multiple invoice upload success response', () {
    const payload = {
      'status': 'success',
      'message': 'Multiple invoices uploaded successfully',
      'shipment_id': '6968676665',
      'total_files_uploaded': 2,
      'files': [
        '6968676665_6a3d1dd3c4074.jpeg',
        '6968676665_6a3d1dd3c4e5d.jpeg',
      ],
    };

    final result = InvoiceUploadResult.fromDynamic(payload);
    expect(result.success, isTrue);
    expect(result.message, 'Multiple invoices uploaded successfully');
    expect(result.shipmentId, '6968676665');
    expect(result.totalFilesUploaded, 2);
    expect(result.files, hasLength(2));
  });

  test('parses upload files returned as invoice file objects', () {
    const payload = {
      'status': 'success',
      'total_files_uploaded': 1,
      'files': [
        {
          'file_name': '6968676665_6a3d1dd3c4074.jpeg',
          'original_name': 'photo.jpg',
          'file_url':
              'https://my.axlpl.com/admin/template/assets/images/invoice_file/6968676665_6a3d1dd3c4074.jpeg',
        },
      ],
    };

    final result = InvoiceUploadResult.fromDynamic(payload);
    expect(result.success, isTrue);
    expect(result.uploadedInvoiceFiles, hasLength(1));
    expect(result.files.single, '6968676665_6a3d1dd3c4074.jpeg');
    expect(
      result.uploadedInvoiceFiles.single.fileUrl,
      contains('6968676665_6a3d1dd3c4074.jpeg'),
    );
  });

  test('parses upload file objects with database id', () {
    const payload = {
      'status': 'success',
      'total_files_uploaded': 1,
      'files': [
        {
          'id': '17',
          'file_name': '6968676665_6a3d1dd3c4074.jpeg',
          'file_url':
              'https://my.axlpl.com/admin/template/assets/images/invoice_file/6968676665_6a3d1dd3c4074.jpeg',
        },
      ],
    };

    final result = InvoiceUploadResult.fromDynamic(payload);
    expect(result.uploadedInvoiceFiles.single.id, '17');
    expect(result.files.single, '6968676665_6a3d1dd3c4074.jpeg');
  });
}
