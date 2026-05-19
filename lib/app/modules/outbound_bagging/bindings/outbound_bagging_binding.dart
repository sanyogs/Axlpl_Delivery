import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/outbound_bagging_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:get/get.dart';

class OutboundBaggingBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
    Get.lazyPut<OutboundBaggingController>(() => OutboundBaggingController());
  }
}
