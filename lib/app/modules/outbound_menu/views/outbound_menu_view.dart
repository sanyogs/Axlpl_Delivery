import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/common_widget/common_appbar.dart';
import 'package:axlpl_delivery/common_widget/common_scaffold.dart';
import 'package:axlpl_delivery/common_widget/home_icon_container.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_menu_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class OutboundMenuView extends StatelessWidget {
  const OutboundMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      appBar: commonAppbar('Outbound'),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _outboundRow(
              HomeIconContainer(
                title: 'Hub scan',
                Img: OutboundMenuIcons.hubScan,
                OnTap: () => Get.toNamed(Routes.OUTBOUND_HUB_SCAN),
              ),
              HomeIconContainer(
                title: 'Bagging',
                Img: OutboundMenuIcons.bagging,
                OnTap: () => Get.toNamed(Routes.OUTBOUND_BAGGING),
              ),
            ),
            SizedBox(height: 10.h),
            _outboundRow(
              HomeIconContainer(
                title: 'Manifest',
                Img: OutboundMenuIcons.manifest,
                OnTap: () => Get.toNamed(Routes.OUTBOUND_MANIFEST),
              ),
              HomeIconContainer(
                title: 'Linehaul',
                Img: OutboundMenuIcons.linehaul,
                OnTap: () => Get.toNamed(Routes.OUTBOUND_LINEHAUL),
              ),
            ),
            SizedBox(height: 10.h),
            _outboundRow(
              HomeIconContainer(
                title: 'Sector pickup',
                Img: OutboundMenuIcons.sectorPickup,
                OnTap: () => Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP),
              ),
              HomeIconContainer(
                title: 'Pickup report',
                Img: OutboundMenuIcons.sectorPickupReport,
                OnTap: () =>
                    Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP_STATUS_REPORT),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Same two-column row pattern as the home dashboard — avoids GridView clipping PNG icons.
  Widget _outboundRow(Widget start, Widget end) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: start),
        SizedBox(width: 10.w),
        Expanded(child: end),
      ],
    );
  }
}
