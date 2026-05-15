import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_linehaul/controllers/outbound_linehaul_controller.dart';
import 'package:get/get.dart';

class OutboundLinehaulBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OutboundRepository>()) {
      Get.lazyPut<OutboundRepository>(
        () => OutboundRepository(),
        fenix: true,
      );
    }
    Get.lazyPut<OutboundLinehaulController>(() => OutboundLinehaulController());
  }
}
