import 'package:axlpl_delivery/app/data/models/tracking_model.dart';
import 'package:axlpl_delivery/app/modules/pickdup_delivery_details/controllers/running_delivery_details_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses invoice_files with ids and suppresses stale legacy file', () {
    final controller = RunningDeliveryDetailsController();
    Get.put(controller);
    const shipmentId = '6968676665';
    const invoicePath =
        'https://my.axlpl.com/admin/template/assets/images/invoice_file/';

    controller.hadMultiInvoiceFiles[shipmentId] = true;

    final files = controller.resolveUploadedInvoiceFiles(
      shipmentId: shipmentId,
      invoicePath: invoicePath,
      invoiceFile: '6968676665_old_legacy.png',
      invoiceFiles: const [
        ShipmentInvoiceFile(
          id: '17',
          fileName: '6968676665_new.png',
          fileUrl:
              'https://my.axlpl.com/admin/template/assets/images/invoice_file/6968676665_new.png',
        ),
      ],
    );

    expect(files, hasLength(1));
    expect(files.first.id, '17');
    expect(files.first.fileName, '6968676665_new.png');
  });

  test('falls back to legacy invoice_file when multi list never used', () {
    final controller = RunningDeliveryDetailsController();
    Get.put(controller);
    const shipmentId = '6968676665';
    const invoicePath =
        'https://my.axlpl.com/admin/template/assets/images/invoice_file/';

    final files = controller.resolveUploadedInvoiceFiles(
      shipmentId: shipmentId,
      invoicePath: invoicePath,
      invoiceFile: '6968676665_single.png',
      invoiceFiles: const [],
    );

    expect(files, hasLength(1));
    expect(files.first.fileName, '6968676665_single.png');
  });

  test('enriches legacy file with cached id', () {
    final controller = RunningDeliveryDetailsController();
    Get.put(controller);
    const shipmentId = '6968676665';
    const invoicePath =
        'https://my.axlpl.com/admin/template/assets/images/invoice_file/';

    controller.invoiceFileIdCache[shipmentId] = {
      '6968676665_cached.png': '42',
    };

    final files = controller.resolveUploadedInvoiceFiles(
      shipmentId: shipmentId,
      invoicePath: invoicePath,
      invoiceFile: '6968676665_cached.png',
      invoiceFiles: const [],
    );

    expect(files.single.id, '42');
  });
}
