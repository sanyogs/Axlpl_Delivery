// notification_service.dart

import 'dart:io';

import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/common_widget/siren_alert_payload.dart';
import 'package:axlpl_delivery/common_widget/siren_alert_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

class NotificationService {
  static const String _sirenSoundKey = 'siren';
  static const String _sirenAssetPath = 'siren.wav';
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final AudioContext _sirenAudioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.notificationEvent,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static NotificationAppLaunchDetails? _launchDetails;
  static SirenAlertPayload? _queuedSirenLaunch;
  static bool _isSirenScreenVisible = false;

  int downloadNotificationId = 1001;
  String downloadChannelKey = 'download_channel';
  LocalStorage storage = LocalStorage();

  static bool _shouldPlaySiren(RemoteMessage message) {
    final dynamic dataSound =
        message.data['sound'] ?? message.data['Sound'] ?? message.data['SOUND'];
    final String? dataSoundValue = switch (dataSound) {
      Map<dynamic, dynamic>() => dataSound['name']?.toString(),
      _ => dataSound?.toString(),
    };

    final String? soundValue = _normalizeSoundValue(dataSoundValue) ??
        _normalizeSoundValue(message.notification?.android?.sound) ??
        _normalizeSoundValue(message.notification?.apple?.sound?.name);

    return soundValue == _sirenSoundKey;
  }

  static bool isSirenMessage(RemoteMessage message) => _shouldPlaySiren(message);

  static String? _normalizeSoundValue(String? raw) {
    if (raw == null) return null;
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) return null;

    final lastSegment = value.split('/').last.split('?').first;
    if (lastSegment.isEmpty) return null;

    final base =
        lastSegment.contains('.') ? lastSegment.split('.').first : lastSegment;
    return base.isEmpty ? null : base;
  }

  static void _playSirenIfNeeded(RemoteMessage message,
      {required bool shouldPlay}) {
    if (kDebugMode) {
      debugPrint(
        'NotificationService: sound=${message.data['sound']} androidSound=${message.notification?.android?.sound} appleSound=${message.notification?.apple?.sound?.name} shouldPlaySiren=$shouldPlay',
      );
    }
    if (!shouldPlay) return;

    () async {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(
          AssetSource(_sirenAssetPath),
          ctx: _sirenAudioContext,
          mode: PlayerMode.lowLatency,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('NotificationService: siren play failed: $e');
        }

        try {
          await _audioPlayer.stop();
          await _audioPlayer.play(
            AssetSource(_sirenAssetPath),
            ctx: _sirenAudioContext,
            mode: PlayerMode.mediaPlayer,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint('NotificationService: siren play fallback failed: $e');
          }
        }
      }
    }();
  }

  static Future<NotificationAppLaunchDetails?> getNotificationLaunchDetails() async {
    _launchDetails ??= await _notificationsPlugin.getNotificationAppLaunchDetails();
    return _launchDetails;
  }

  static void queueSirenLaunch(SirenAlertPayload payload) {
    _queuedSirenLaunch = payload;
  }

  static SirenAlertPayload? consumeQueuedSirenLaunch() {
    final queued = _queuedSirenLaunch;
    _queuedSirenLaunch = null;
    return queued;
  }

  static bool _canPresentUI() {
    try {
      return Get.key.currentContext != null;
    } catch (_) {
      return false;
    }
  }

  static void showSirenAlertScreen(SirenAlertPayload payload) {
    if (_isSirenScreenVisible) return;
    if (!_canPresentUI()) {
      queueSirenLaunch(payload);
      return;
    }
    _isSirenScreenVisible = true;
    final navigation = Get.to(
      () => SirenAlertScreen(payload: payload),
      fullscreenDialog: true,
    );
    if (navigation == null) {
      _isSirenScreenVisible = false;
      return;
    }
    navigation.whenComplete(() {
      _isSirenScreenVisible = false;
    });
  }

  static Future<void> init({bool requestPermissions = true}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final sirenPayload = SirenAlertPayload.tryDecode(response.payload);
        if (sirenPayload != null) {
          showSirenAlertScreen(sirenPayload);
        }

        print("Action clicked: ${response.actionId}");

        if (response.actionId == 'accept') {
          print("✅ ACCEPTED");
          // Handle accept logic here
        } else if (response.actionId == 'reject') {
          print("❌ REJECTED");
        }
      },
    );

    // Create pickup notification channel (with actions)
    const AndroidNotificationChannel pickupChannel = AndroidNotificationChannel(
      'pickup_channel',
      'Pickup Notifications',
      description:
          'Notifications for pickup requests with accept/reject actions',
      importance: Importance.high,
    );

    // Create delivery status channel (no actions)
    const AndroidNotificationChannel deliveryStatusChannel =
        AndroidNotificationChannel(
      'delivery_status_channel',
      'Delivery Status Notifications',
      description: 'Notifications for delivery status updates',
      importance: Importance.high,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(pickupChannel);
    await androidPlugin?.createNotificationChannel(deliveryStatusChannel);

    if (requestPermissions && Platform.isAndroid) {
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  // Pickup notification with accept/reject buttons (for messengers)
  static void showPickupNotification(
    RemoteMessage message, {
    required bool useFullScreenIntent,
    String? payloadOverride,
  }) {
    final data = message.data;
    final title =
        data['title'] ?? message.notification?.title ?? 'New Pickup Request';
    final body = data['body'] ??
        message.notification?.body ??
        'Do you accept this pickup?';

    _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'pickup_channel',
          'Pickup Notifications',
          icon: 'ic_notification',
          importance: Importance.max,
          priority: useFullScreenIntent ? Priority.max : Priority.high,
          color: Colors.orange,
          category:
              useFullScreenIntent ? AndroidNotificationCategory.call : null,
          visibility:
              useFullScreenIntent ? NotificationVisibility.public : null,
          fullScreenIntent: useFullScreenIntent,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction('accept', 'Accept',
                showsUserInterface: true),
            AndroidNotificationAction('reject', 'Reject',
                showsUserInterface: true),
          ],
        ),
      ),
      payload: payloadOverride ?? 'pickup',
    );
  }

  // Out for delivery notification - no action buttons
  static void showOutForDeliveryNotification(
    RemoteMessage message, {
    required bool useFullScreenIntent,
    String? payloadOverride,
  }) {
    final data = message.data;
    final title =
        data['title'] ?? message.notification?.title ?? 'Out for Delivery';
    final body = data['body'] ??
        message.notification?.body ??
        'Your package is out for delivery';

    _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2, // Different ID
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'delivery_status_channel',
          'Delivery Status Notifications',
          icon: 'ic_notification',
          importance: Importance.max,
          priority: useFullScreenIntent ? Priority.max : Priority.high,
          color: Colors.green,
          category:
              useFullScreenIntent ? AndroidNotificationCategory.call : null,
          visibility:
              useFullScreenIntent ? NotificationVisibility.public : null,
          fullScreenIntent: useFullScreenIntent,
          // No actions for out for delivery notifications
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'out_for_delivery',
        ),
      ),
      payload: payloadOverride ?? 'out_for_delivery',
    );
  }

  // Customer notification - only title and message (no action buttons)
  static void showCustomerNotification(
    RemoteMessage message, {
    required bool useFullScreenIntent,
    String? payloadOverride,
  }) {
    final data = message.data;
    final title =
        data['title'] ?? message.notification?.title ?? 'Delivery Update';
    final body = data['body'] ??
        message.notification?.body ??
        'Your delivery status has been updated';

    _notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1, // Different ID
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'delivery_status_channel',
          'Delivery Status Notifications',
          icon: 'ic_notification',
          importance: Importance.max,
          priority: useFullScreenIntent ? Priority.max : Priority.high,
          color: Colors.blue,
          category:
              useFullScreenIntent ? AndroidNotificationCategory.call : null,
          visibility:
              useFullScreenIntent ? NotificationVisibility.public : null,
          fullScreenIntent: useFullScreenIntent,
          // No actions - only title and message for customers
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'customer_delivery',
        ),
      ),
      payload: payloadOverride ?? 'customer_notification',
    );
  }

  // Smart notification method based on message data
  static void showNotificationByType(
    RemoteMessage message, {
    required bool useFullScreenIntent,
    String? payloadOverride,
  }) {
    final data = message.data;
    final notificationType = data['type'] ?? '';
    final status = data['status'] ?? '';
    final title = data['title'] ?? message.notification?.title ?? '';

    // Check title for notification type
    if (title.toLowerCase().contains('out for delivery') ||
        notificationType == 'out_for_delivery' ||
        status == 'out_for_delivery') {
      showOutForDeliveryNotification(
        message,
        useFullScreenIntent: useFullScreenIntent,
        payloadOverride: payloadOverride,
      );
    } else if (title.toLowerCase().contains('pickup') ||
        notificationType == 'pickup' ||
        status == 'pickup') {
      showPickupNotification(
        message,
        useFullScreenIntent: useFullScreenIntent,
        payloadOverride: payloadOverride,
      );
    } else if (title.toLowerCase().contains('delivered') ||
        notificationType == 'customer' ||
        status == 'delivered') {
      showCustomerNotification(
        message,
        useFullScreenIntent: useFullScreenIntent,
        payloadOverride: payloadOverride,
      );
    } else {
      // Default to pickup notification for backward compatibility
      showPickupNotification(
        message,
        useFullScreenIntent: useFullScreenIntent,
        payloadOverride: payloadOverride,
      );
    }
  }

  // Keep the original method for backward compatibility
  static void showNotification(RemoteMessage message) {
    final shouldPlaySiren = _shouldPlaySiren(message);
    _playSirenIfNeeded(message, shouldPlay: shouldPlaySiren);

    final SirenAlertPayload? sirenPayload =
        shouldPlaySiren ? SirenAlertPayload.fromRemoteMessage(message) : null;

    // Use the smart method to determine notification type
    showNotificationByType(
      message,
      useFullScreenIntent: shouldPlaySiren,
      payloadOverride: sirenPayload?.encode(),
    );

    if (sirenPayload != null) {
      showSirenAlertScreen(sirenPayload);
    }
  }

  static void showBackgroundNotification(RemoteMessage message) {
    final shouldPlaySiren = _shouldPlaySiren(message);
    final sirenPayload = shouldPlaySiren
        ? SirenAlertPayload.fromRemoteMessage(message).encode()
        : null;

    showNotificationByType(
      message,
      useFullScreenIntent: shouldPlaySiren,
      payloadOverride: sirenPayload,
    );
  }
}
