import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_remote_detail/controllers/outbound_remote_detail_controller.dart';
import 'package:get/get.dart';

class OutboundRemoteDetailBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OutboundRepository>()) {
      Get.lazyPut<OutboundRepository>(
        () => OutboundRepository(),
        fenix: true,
      );
    }
    Get.lazyPut<OutboundRemoteDetailController>(
      () => OutboundRemoteDetailController(),
    );
  }
}
