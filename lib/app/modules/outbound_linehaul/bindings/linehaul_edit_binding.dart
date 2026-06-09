import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/linehaul_edit_controller.dart';
import 'package:get/get.dart';

class LinehaulEditBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
    Get.lazyPut<LinehaulEditController>(() => LinehaulEditController());
  }
}
