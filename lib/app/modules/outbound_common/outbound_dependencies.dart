import 'package:axlpl_delivery/app/data/networking/repostiory/outbound_repository.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_branch_list_controller.dart';
import 'package:get/get.dart';

/// Shared GetX registrations for all outbound routes.
class OutboundDependencies {
  OutboundDependencies._();

  static void registerCore() {
    if (!Get.isRegistered<OutboundRepository>()) {
      Get.lazyPut<OutboundRepository>(
        () => OutboundRepository(),
        fenix: true,
      );
    }
    if (!Get.isRegistered<OutboundBranchListController>()) {
      Get.put<OutboundBranchListController>(
        OutboundBranchListController(),
        permanent: true,
      );
    }
  }
}
