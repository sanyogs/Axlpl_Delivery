// notification_service.dart

import 'dart:io';

import 'package:axlpl_delivery/app/data/localstorage/local_storage.dart';
import 'package:axlpl_delivery/app/routes/app_pages.dart';
import 'package:axlpl_delivery/common_widget/siren_alert_payload.dart';
import 'package:axlpl_delivery/common_widget/siren_alert_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';

enum _NotificationKind {
  pickup,
  outForDelivery,
  customer,
}

class _NotificationActionDefinition {
  const _NotificationActionDefinition(this.id, this.label);

  final String id;
  final String label;

  AndroidNotificationAction toAndroid() => AndroidNotificationAction(
        id,
        label,
        showsUserInterface: true,
      );

  SirenAlertAction toSiren() => SirenAlertAction(id: id, label: label);
}

class NotificationService {
  static const String _sirenSoundKey = 'siren';
  static const String _sirenAssetPath = 'siren.wav';
  static const String _pickupTitleBase = 'New Pickup Available';

  static const List<_NotificationActionDefinition> _pickupActions =
      <_NotificationActionDefinition>[
    _NotificationActionDefinition('accept', 'Accept'),
    _NotificationActionDefinition('reject', 'Reject'),
  ];

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
    // Trigger siren/full-screen only when the incoming FCM payload indicates
    // `sound: siren`. Backend may send it either in data or in the platform
    // notification object; handle null/empty gracefully.
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

  static bool isSirenPayload(SirenAlertPayload payload) {
    final raw = payload.data['sound']?.toString();
    return _normalizeSoundValue(raw) == _sirenSoundKey;
  }

  static SirenAlertPayload buildSirenPayload(RemoteMessage message) {
    final kind = _kindForMessage(message);
    final title = _titleForMessage(message, kind);
    final body = _bodyForMessage(message, kind);

    return SirenAlertPayload.fromRemoteMessage(
      message,
      titleOverride: title,
      bodyOverride: body,
      actions: _sirenActionsForKind(kind),
    );
  }

  static String? _stringFromData(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static String? _firstStringFromData(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = _stringFromData(data, key);
      if (value != null) return value;
    }
    return null;
  }

  static _NotificationKind _kindForMessage(RemoteMessage message) {
    final data = message.data;
    final type =
        (_stringFromData(data, 'type') ?? _stringFromData(data, 'notification_type') ?? '')
            .toLowerCase();
    final status = (_stringFromData(data, 'status') ?? '').toLowerCase();
    final title =
        (_stringFromData(data, 'title') ?? message.notification?.title ?? '')
            .toLowerCase();

    if (title.contains('out for delivery') ||
        type == 'out_for_delivery' ||
        status == 'out_for_delivery') {
      return _NotificationKind.outForDelivery;
    }
    if (title.contains('pickup') || type == 'pickup' || status == 'pickup') {
      return _NotificationKind.pickup;
    }
    if (title.contains('delivered') || type == 'customer' || status == 'delivered') {
      return _NotificationKind.customer;
    }

    return _NotificationKind.pickup;
  }

  static String _titleForMessage(RemoteMessage message, _NotificationKind kind) {
    final data = message.data;

    return switch (kind) {
      _NotificationKind.pickup => () {
          final area = _firstStringFromData(
            data,
            const ['area', 'Area', 'pickup_area', 'pickupArea'],
          );
          return area == null ? _pickupTitleBase : '$_pickupTitleBase - $area';
        }(),
      _NotificationKind.outForDelivery =>
        _firstStringFromData(data, const ['title']) ??
            message.notification?.title ??
            'Out for Delivery',
      _NotificationKind.customer =>
        _firstStringFromData(data, const ['title']) ??
            message.notification?.title ??
            'Delivery Update',
    };
  }

  static String _bodyForMessage(RemoteMessage message, _NotificationKind kind) {
    final data = message.data;
    final body = _firstStringFromData(data, const ['body', 'message']) ??
        message.notification?.body;

    if (body != null && body.trim().isNotEmpty) return body.trim();

    return switch (kind) {
      _NotificationKind.pickup => 'Do you accept this pickup?',
      _NotificationKind.outForDelivery => 'Your package is out for delivery',
      _NotificationKind.customer => 'Your delivery status has been updated',
    };
  }

  static List<SirenAlertAction> _sirenActionsForKind(_NotificationKind kind) {
    return switch (kind) {
      _NotificationKind.pickup => _pickupActions.map((a) => a.toSiren()).toList(),
      _NotificationKind.outForDelivery => const <SirenAlertAction>[],
      _NotificationKind.customer => const <SirenAlertAction>[],
    };
  }

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
        'NotificationService: dataSound=${message.data['sound']} androidSound=${message.notification?.android?.sound} appleSound=${message.notification?.apple?.sound?.name} shouldPlaySiren=$shouldPlay',
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

  static void _playSirenNow() {
    () async {
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
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
          await _audioPlayer.setReleaseMode(ReleaseMode.loop);
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

  static void handleSirenAction(SirenAlertAction action, SirenAlertPayload payload) {
    if (kDebugMode) {
      debugPrint('NotificationService: siren action=${action.id}');
    }

    () async {
      try {
        await _audioPlayer.stop();
      } catch (_) {}
    }();

    if (_isSirenScreenVisible) {
      final navigator = Get.key.currentState;
      if (navigator?.canPop() == true) {
        navigator?.pop();
      }
    }

    if (kDebugMode) {
      if (action.id == 'accept') {
        debugPrint('NotificationService: ✅ ACCEPTED');
      } else if (action.id == 'reject') {
        debugPrint('NotificationService: ❌ REJECTED');
      }
    }

    // Requirement: when user acts (accept/reject), go to dashboard.
    // For non-siren cases, we never show the siren screen in the first place.
    Get.offAllNamed(AppPages.INITIAL);
  }

  static void showSirenAlertScreen(SirenAlertPayload payload) {
    if (_isSirenScreenVisible) return;
    if (!_canPresentUI()) {
      queueSirenLaunch(payload);
      return;
    }
    _playSirenNow();
    if (kDebugMode && payload.actions.isNotEmpty) {
      debugPrint(
        'NotificationService: siren screen actions=${payload.actions.map((a) => a.id).join(',')}',
      );
    }
    _isSirenScreenVisible = true;
    final navigation = Get.to(
      () => SirenAlertScreen(
        payload: payload,
        onActionPressed: (action) => handleSirenAction(action, payload),
      ),
      fullscreenDialog: true,
    );
    if (navigation == null) {
      _isSirenScreenVisible = false;
      return;
    }
    navigation.whenComplete(() {
      _isSirenScreenVisible = false;
      () async {
        try {
          await _audioPlayer.stop();
        } catch (_) {}
      }();
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
        final actionId = response.actionId;
        final isActionTap = response.notificationResponseType ==
            NotificationResponseType.selectedNotificationAction;

        if (sirenPayload != null &&
            isActionTap &&
            actionId != null &&
            actionId.trim().isNotEmpty) {
          final resolvedActionId = actionId.trim();
          final action = sirenPayload.actions.firstWhere(
            (item) => item.id == resolvedActionId,
            orElse: () => SirenAlertAction(
              id: resolvedActionId,
              label: resolvedActionId,
            ),
          );
          handleSirenAction(action, sirenPayload);
        } else if (sirenPayload != null) {
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
    final kind = _NotificationKind.pickup;
    final title = _titleForMessage(message, kind);
    final body = _bodyForMessage(message, kind);

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
          actions: _pickupActions.map((a) => a.toAndroid()).toList(),
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
    final kind = _NotificationKind.outForDelivery;
    final title = _titleForMessage(message, kind);
    final body = _bodyForMessage(message, kind);

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
    final kind = _NotificationKind.customer;
    final title = _titleForMessage(message, kind);
    final body = _bodyForMessage(message, kind);

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
    switch (_kindForMessage(message)) {
      case _NotificationKind.outForDelivery:
        showOutForDeliveryNotification(
          message,
          useFullScreenIntent: useFullScreenIntent,
          payloadOverride: payloadOverride,
        );
        break;
      case _NotificationKind.customer:
        showCustomerNotification(
          message,
          useFullScreenIntent: useFullScreenIntent,
          payloadOverride: payloadOverride,
        );
        break;
      case _NotificationKind.pickup:
        showPickupNotification(
          message,
          useFullScreenIntent: useFullScreenIntent,
          payloadOverride: payloadOverride,
        );
        break;
    }
  }

  // Keep the original method for backward compatibility
  static void showNotification(RemoteMessage message) {
    final shouldPlaySiren = _shouldPlaySiren(message);
    _playSirenIfNeeded(message, shouldPlay: shouldPlaySiren);

    final kind = _kindForMessage(message);
    final title = _titleForMessage(message, kind);
    final body = _bodyForMessage(message, kind);

    final SirenAlertPayload? sirenPayload = shouldPlaySiren
        ? SirenAlertPayload.fromRemoteMessage(
            message,
            titleOverride: title,
            bodyOverride: body,
            actions: _sirenActionsForKind(kind),
          )
        : null;

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
    _playSirenIfNeeded(message, shouldPlay: shouldPlaySiren);
    final kind = _kindForMessage(message);
    final title = _titleForMessage(message, kind);
    final body = _bodyForMessage(message, kind);
    final sirenPayload = shouldPlaySiren
        ? SirenAlertPayload.fromRemoteMessage(
            message,
            titleOverride: title,
            bodyOverride: body,
            actions: _sirenActionsForKind(kind),
          ).encode()
        : null;

    showNotificationByType(
      message,
      useFullScreenIntent: shouldPlaySiren,
      payloadOverride: sirenPayload,
    );
  }
}
