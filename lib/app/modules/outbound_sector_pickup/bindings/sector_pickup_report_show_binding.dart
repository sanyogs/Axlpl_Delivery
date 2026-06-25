import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:axlpl_delivery/app/modules/outbound_sector_pickup/controllers/sector_pickup_report_show_controller.dart';
import 'package:get/get.dart';

class SectorPickupReportShowBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
    Get.lazyPut<SectorPickupReportShowController>(
      () => SectorPickupReportShowController(),
    );
  }
}
