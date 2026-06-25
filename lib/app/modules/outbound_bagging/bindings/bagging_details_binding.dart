import 'package:axlpl_delivery/app/modules/outbound_bagging/controllers/bagging_details_controller.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:get/get.dart';

class BaggingDetailsBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
    Get.lazyPut<BaggingDetailsController>(
      () => BaggingDetailsController(),
      fenix: true,
    );
  }
}
