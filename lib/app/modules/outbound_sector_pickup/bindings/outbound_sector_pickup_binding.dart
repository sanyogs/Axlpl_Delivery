import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/outbound_sector_pickup_controller.dart';
import 'package:get/get.dart';

class OutboundSectorPickupBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OutboundRepository>()) {
      Get.lazyPut<OutboundRepository>(
        () => OutboundRepository(),
        fenix: true,
      );
    }
    Get.lazyPut<OutboundSectorPickupController>(
      () => OutboundSectorPickupController(),
    );
  }
}
