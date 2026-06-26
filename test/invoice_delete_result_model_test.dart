import 'package:axlpl_delivery/app/data/models/invoice_delete_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses full delete invoice file success response', () {
    const payload = {
      'status': 'success',
      'message': 'Invoice file deleted successfully',
      'data': {
        'id': 3,
        'file_name': '6968676665_6a3d185235131.png',
      },
    };

    final result = InvoiceDeleteResult.fromDynamic(payload);
    expect(result.success, isTrue);
    expect(result.message, 'Invoice file deleted successfully');
    expect(result.id, '3');
    expect(result.fileName, '6968676665_6a3d185235131.png');
  });

  test('parses unwrapped delete invoice file success payload', () {
    const payload = {
      'id': 3,
      'file_name': '6968676665_6a3d185235131.png',
      '__server_message': 'Invoice file deleted successfully',
    };

    final result = InvoiceDeleteResult.fromDynamic(payload);
    expect(result.success, isTrue);
    expect(result.message, 'Invoice file deleted successfully');
    expect(result.id, '3');
  });
}
