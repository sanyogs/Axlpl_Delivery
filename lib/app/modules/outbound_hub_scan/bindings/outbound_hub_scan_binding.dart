import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_hub_scan/controllers/outbound_hub_scan_controller.dart';
import 'package:get/get.dart';

class OutboundHubScanBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OutboundRepository>()) {
      Get.lazyPut<OutboundRepository>(
        () => OutboundRepository(),
        fenix: true,
      );
    }
    Get.lazyPut<OutboundHubScanController>(() => OutboundHubScanController());
  }
}
