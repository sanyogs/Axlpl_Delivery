import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:axlpl_delivery/app/modules/outbound_manifest/controllers/outbound_manifest_controller.dart';
import 'package:get/get.dart';

class OutboundManifestBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
    Get.lazyPut<OutboundManifestController>(
      () => OutboundManifestController(),
    );
  }
}
