import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutboundMenuView extends StatelessWidget {
  const OutboundMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: themes.lightWhite,
      appBar: AppBar(
        title: const Text('Outbound'),
        backgroundColor: themes.whiteColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(
            title: 'Hub scan',
            subtitle: 'Docket scan, logs, shipment scan history',
            route: Routes.OUTBOUND_HUB_SCAN,
          ),
          _tile(
            title: 'Bagging',
            subtitle: 'Create bag, add shipments, lock',
            route: Routes.OUTBOUND_BAGGING,
          ),
          _tile(
            title: 'Manifest',
            subtitle: 'Create, list, reports',
            route: Routes.OUTBOUND_MANIFEST,
          ),
          _tile(
            title: 'Linehaul',
            subtitle: 'Assign, list, status, reports',
            route: Routes.OUTBOUND_LINEHAUL,
          ),
          _tile(
            title: 'Sector pickup',
            subtitle: 'Pickup list, scan, missed / not picked',
            route: Routes.OUTBOUND_SECTOR_PICKUP,
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required String route,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.toNamed(route),
      ),
    );
  }
}
