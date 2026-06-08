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
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
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
                  HomeIconContainer(
                    title: 'Sector pickup',
                    Img: OutboundMenuIcons.sectorPickup,
                    OnTap: () => Get.toNamed(Routes.OUTBOUND_SECTOR_PICKUP),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
