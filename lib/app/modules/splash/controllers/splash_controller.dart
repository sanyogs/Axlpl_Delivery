import 'dart:developer';

import 'package:axlpl_delivery/app/data/networking/api_client.dart';
import 'package:axlpl_delivery/app/data/networking/api_endpoint.dart';
import 'package:axlpl_delivery/common_widget/force_update_dialog.dart';
import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/common_widget/local_notification.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  //TODO: Implement SplashController
  final ApiClient _apiClient = ApiClient();

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
      final response = await _apiClient.getRaw(getPaymentModePoint);
      final responseData = response?.data;

      if (_isForceUpdatePayload(responseData)) {
        final payload = _extractForceUpdatePayload(responseData);
        showForceUpdateDialog(
          message: payload['message']?.toString(),
          updateUrl: payload['update_url']?.toString(),
        );
        return;
      }
    } catch (e) {
      log('Version check failed: $e');
    }

    keepLogin();
  }

  bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'y';
    }
    return false;
  }

  bool _isForceUpdatePayload(dynamic raw) {
    if (raw is! Map) return false;
    final payload = _extractForceUpdatePayload(raw);
    final status = payload['status']?.toString().trim().toLowerCase();
    final forceUpdate = _isTruthy(payload['force_update']);
    return status == 'fail' && forceUpdate;
  }

  Map<String, dynamic> _extractForceUpdatePayload(Map source) {
    final topLevel = <String, dynamic>{};
    source.forEach((key, value) {
      topLevel[key.toString()] = value;
    });

    final nestedDataRaw = topLevel['data'];
    if (nestedDataRaw is Map) {
      final nested = <String, dynamic>{};
      nestedDataRaw.forEach((key, value) {
        nested[key.toString()] = value;
      });
      return {
        ...nested,
        ...topLevel,
      };
    }

    return topLevel;
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
