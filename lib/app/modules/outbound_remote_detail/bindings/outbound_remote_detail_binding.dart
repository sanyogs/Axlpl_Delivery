import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:axlpl_delivery/app/modules/outbound_remote_detail/controllers/outbound_remote_detail_controller.dart';
import 'package:get/get.dart';

class OutboundRemoteDetailBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
    Get.lazyPut<OutboundRemoteDetailController>(
      () => OutboundRemoteDetailController(),
    );
  }
}
