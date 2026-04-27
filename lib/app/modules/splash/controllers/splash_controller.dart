import 'dart:developer';

import 'package:axlpl_delivery/common_widget/force_update_dialog.dart';
import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/const/app_update_config.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/common_widget/local_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashController extends GetxController {
  //TODO: Implement SplashController
  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('🔔 Received a foreground message!');
      log('Title: ${message.notification?.title}');
      log('Body: ${message.notification?.body}');
      log('Data: ${message.data}');

      // Optional: show a local notification
      NotificationService.showNotification(message);
    });
    _checkAppVersion();
  }

  Future<void> _checkAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion =
          '${packageInfo.version}+${packageInfo.buildNumber}';

      if (AppUpdateConfig.requiresUpdate(currentVersion)) {
        showForceUpdateDialog();
        return;
      }
    } catch (e) {
      log('Version check failed: $e');
    }

    keepLogin();
  }

  void keepLogin() {
    Future.delayed(const Duration(seconds: 3), () async {
      final userData = await LocalStorage().getUserLocalData();
      final role = await storage.read(key: LocalStorage().userRole);

      if (userData == null || role == null) {
        Get.offAllNamed(Routes.AUTH);
        return;
      }

      if (role == "messanger") {
        // Get.offAllNamed(Routes.BOTTOMBAR, arguments: userData);
        Get.offAllNamed(Routes.HOME);
        log('🤩 Messenger Login success 🤩');
      } else if (role == "customer") {
        // Get.offAllNamed(Routes.BOTTOMBAR, arguments: userData);
        Get.offAllNamed(Routes.HOME);
        log('🤩 Customer Login success 🤩');
      } else {
        Get.offAllNamed(Routes.AUTH);
      }
    });
  }
}
