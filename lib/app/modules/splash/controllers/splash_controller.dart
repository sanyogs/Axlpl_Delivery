import 'dart:async';
import 'dart:developer';

import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/data/networking/api_client.dart';
import 'package:axlpl_delivery/app/data/networking/api_endpoint.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/common_widget/local_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  final ApiClient _apiClient = ApiClient();
  bool _navigated = false;

  @override
  void onInit() {
    super.onInit();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('🔔 Received a foreground message!');
      log('Title: ${message.notification?.title}');
      log('Body: ${message.notification?.body}');
      log('Data: ${message.data}');
      NotificationService.showNotification(message);
    });
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      _checkAppVersion(),
      Future.delayed(const Duration(seconds: 3)),
    ]);
    await _navigateFromStorage();
  }

  Future<void> _checkAppVersion() async {
    try {
      // Force-update dialog is handled inside ApiClient.getRaw when applicable.
      await _apiClient.getRaw(getPaymentModePoint).timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              log('Version check timed out — continuing to app');
              return null;
            },
          );
    } catch (e, st) {
      log('Version check failed: $e', stackTrace: st);
    }
  }

  Future<void> _navigateFromStorage() async {
    if (_navigated) return;
    _navigated = true;

    try {
      final userData = await LocalStorage().getUserLocalData();
      final role = await storage.read(key: LocalStorage().userRole);

      if (userData == null || role == null || role.trim().isEmpty) {
        Get.offAllNamed(Routes.AUTH);
        return;
      }

      final normalizedRole = role.trim().toLowerCase();
      if (normalizedRole == 'messanger' || normalizedRole == 'messenger') {
        Get.offAllNamed(Routes.HOME);
        log('🤩 Messenger login restored');
      } else if (normalizedRole == 'customer') {
        Get.offAllNamed(Routes.HOME);
        log('🤩 Customer login restored');
      } else {
        Get.offAllNamed(Routes.AUTH);
      }
    } catch (e, st) {
      log('Splash navigation failed: $e', stackTrace: st);
      Get.offAllNamed(Routes.AUTH);
    }
  }
}
