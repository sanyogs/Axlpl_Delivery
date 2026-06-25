import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/sector_pickup_status_report_controller.dart';
import 'package:get/get.dart';

class SectorPickupStatusReportBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
    Get.lazyPut<SectorPickupStatusReportController>(
      () => SectorPickupStatusReportController(),
    );
  }
}
