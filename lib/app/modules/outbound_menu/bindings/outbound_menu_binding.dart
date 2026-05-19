import 'package:axlpl_delivery/app/modules/outbound_common/outbound_dependencies.dart';
import 'package:get/get.dart';

class OutboundMenuBinding extends Bindings {
  @override
  void dependencies() {
    OutboundDependencies.registerCore();
  }
}
