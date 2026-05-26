import 'package:get/get.dart';

import '../modules/add_shipment/bindings/add_shipment_binding.dart';
import '../modules/add_shipment/views/add_shipment_view.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/auth_view.dart';
import '../modules/bottombar/bindings/bottombar_binding.dart';
import '../modules/bottombar/views/bottombar_view.dart';
import '../modules/consignment/bindings/consignment_binding.dart';
import '../modules/consignment/views/consignment_view.dart';
import '../modules/delivery/bindings/delivery_binding.dart';
import '../modules/delivery/views/delivery_view.dart';
import '../modules/history/bindings/history_binding.dart';
import '../modules/history/views/cash_collection_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/myorders/bindings/myorders_binding.dart';
import '../modules/myorders/views/myorders_view.dart';
import '../modules/notification/bindings/notification_binding.dart';
import '../modules/notification/views/notification_view.dart';
import '../modules/outbound_bagging/bindings/outbound_bagging_binding.dart';
import '../modules/outbound_bagging/views/outbound_bagging_view.dart';
import '../modules/outbound_hub_scan/bindings/outbound_hub_scan_binding.dart';
import '../modules/outbound_hub_scan/views/hub_scan_list_view.dart';
import '../modules/outbound_hub_scan/views/outbound_hub_scan_view.dart';
import '../modules/outbound_linehaul/bindings/outbound_linehaul_binding.dart';
import '../modules/outbound_linehaul/views/outbound_linehaul_view.dart';
import '../modules/outbound_manifest/bindings/outbound_manifest_binding.dart';
import '../modules/outbound_manifest/views/outbound_manifest_view.dart';
import '../modules/outbound_menu/bindings/outbound_menu_binding.dart';
import '../modules/outbound_menu/views/outbound_menu_view.dart';
import '../modules/outbound_remote_detail/bindings/outbound_remote_detail_binding.dart';
import '../modules/outbound_remote_detail/views/outbound_remote_detail_view.dart';
import '../modules/outbound_sector_pickup/bindings/outbound_sector_pickup_binding.dart';
import '../modules/outbound_sector_pickup/views/outbound_sector_pickup_view.dart';
import '../modules/pickdup_delivery_details/bindings/running_delivery_details_binding.dart';
import '../modules/pickdup_delivery_details/views/running_delivery_details_view.dart';
import '../modules/pickup/bindings/pickup_binding.dart';
import '../modules/pickup/views/pickup_view.dart';
import '../modules/pod/bindings/pod_binding.dart';
import '../modules/pod/views/pod_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';

import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/shipment_record/bindings/shipment_record_binding.dart';
import '../modules/shipment_record/views/shipment_record_view.dart';
import '../modules/shipnow/bindings/shipnow_binding.dart';
import '../modules/shipnow/views/shipnow_view.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.AUTH,
      page: () => const AuthView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.BOTTOMBAR,
      page: () => const BottombarView(),
      binding: BottombarBinding(),
    ),
    GetPage(
      name: _Paths.SHIPNOW,
      page: () => const ShipnowView(),
      binding: ShipnowBinding(),
      children: [
        GetPage(
          name: _Paths.SHIPNOW,
          page: () => const ShipnowView(),
          binding: ShipnowBinding(),
        ),
      ],
    ),
    GetPage(
      name: _Paths.HISTORY,
      page: () => const HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: _Paths.PICKUP,
      page: () => const PickupView(),
      binding: PickupBinding(),
    ),
    GetPage(
      name: _Paths.POD,
      page: () => const PodView(),
      binding: PodBinding(),
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => const ProfileView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: _Paths.CONSIGNMENT,
      page: () => const ConsignmentView(),
      binding: ConsignmentBinding(),
    ),
    GetPage(
      name: _Paths.RUNNING_DELIVERY_DETAILS,
      page: () => RunningDeliveryDetailsView(),
      binding: RunningDeliveryDetailsBinding(),
    ),
    GetPage(
      name: _Paths.ADD_SHIPMENT,
      page: () => const AddShipmentView(),
      binding: AddShipmentBinding(),
    ),
    GetPage(
      name: _Paths.DELIVERY,
      page: () => const DeliveryView(),
      binding: DeliveryBinding(),
    ),
    GetPage(
      name: _Paths.NOTIFICATION,
      page: () => const NotificationView(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: _Paths.MYORDERS,
      page: () => const MyordersView(),
      binding: MyordersBinding(),
    ),
    GetPage(
      name: _Paths.SHIPMENT_RECORD,
      page: () => const ShipmentRecordView(),
      binding: ShipmentRecordBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.OUTBOUND_MENU,
      page: () => const OutboundMenuView(),
      binding: OutboundMenuBinding(),
    ),
    GetPage(
      name: _Paths.OUTBOUND_HUB_SCAN,
      page: () => const OutboundHubScanView(),
      binding: OutboundHubScanBinding(),
    ),
    GetPage(
      name: _Paths.OUTBOUND_HUB_SCAN_LIST,
      page: () => const HubScanListView(),
    ),
    GetPage(
      name: _Paths.OUTBOUND_BAGGING,
      page: () => const OutboundBaggingView(),
      binding: OutboundBaggingBinding(),
    ),
    GetPage(
      name: _Paths.OUTBOUND_MANIFEST,
      page: () => const OutboundManifestView(),
      binding: OutboundManifestBinding(),
    ),
    GetPage(
      name: _Paths.OUTBOUND_LINEHAUL,
      page: () => const OutboundLinehaulView(),
      binding: OutboundLinehaulBinding(),
    ),
    GetPage(
      name: _Paths.OUTBOUND_SECTOR_PICKUP,
      page: () => const OutboundSectorPickupView(),
      binding: OutboundSectorPickupBinding(),
    ),
    GetPage(
      name: _Paths.OUTBOUND_REMOTE_DETAIL,
      page: () => const OutboundRemoteDetailView(),
      binding: OutboundRemoteDetailBinding(),
    ),
  ];
}
