import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_manifest/controllers/outbound_manifest_controller.dart';
import 'package:get/get.dart';

class OutboundManifestBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OutboundRepository>()) {
      Get.lazyPut<OutboundRepository>(
        () => OutboundRepository(),
        fenix: true,
      );
    }
    Get.lazyPut<OutboundManifestController>(() => OutboundManifestController());
  }
}
