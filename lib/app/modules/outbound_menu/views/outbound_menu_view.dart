import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/common_widget/common_appbar.dart';
import 'package:axlpl_delivery/common_widget/common_scaffold.dart';
import 'package:axlpl_delivery/app/modules/outbound_common/outbound_menu_icons.dart';
import 'package:axlpl_delivery/app/modules/outbound_menu/widgets/outbound_menu_tile.dart';
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
              OutboundMenuTile(
                title: 'Hub scan',
                assetPath: OutboundMenuIcons.hubScan,
                onTap: () => Get.toNamed(Routes.OUTBOUND_HUB_SCAN),
              ),
              OutboundMenuTile(
                title: 'Bagging',
                assetPath: OutboundMenuIcons.bagging,
                onTap: () => Get.toNamed(Routes.OUTBOUND_BAGGING),
              ),
            ),
            SizedBox(height: 10.h),
            _outboundRow(
              OutboundMenuTile(
                title: 'Manifest',
                assetPath: OutboundMenuIcons.manifest,
                onTap: () => Get.toNamed(Routes.OUTBOUND_MANIFEST),
              ),
              OutboundMenuTile(
                title: 'Linehaul',
                assetPath: OutboundMenuIcons.linehaul,
                onTap: () => Get.toNamed(Routes.OUTBOUND_LINEHAUL),
              ),
            ),
            SizedBox(height: 10.h),
            _outboundRow(
              OutboundMenuTile(
                title: 'Sector pickup',
                assetPath: OutboundMenuIcons.sectorPickup,
                onTap: () => Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP),
              ),
              OutboundMenuTile(
                title: 'Pickup report',
                assetPath: OutboundMenuIcons.sectorPickupReport,
                onTap: () =>
                    Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP_STATUS_REPORT),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
