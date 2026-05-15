import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:get/get.dart';

/// Ensures [OutboundRepository] is registered before any outbound submodule route.
class OutboundMenuBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<OutboundRepository>()) {
      Get.lazyPut<OutboundRepository>(
        () => OutboundRepository(),
        fenix: true,
      );
    }
  }
}
