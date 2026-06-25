import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/linehaul_pre_alert_controller.dart';
import 'package:get/get.dart';

class LinehaulPreAlertBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
    Get.lazyPut<LinehaulPreAlertController>(
      () => LinehaulPreAlertController(),
      fenix: true,
    );
  }
}
