import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

class SirenAlertPayload {
  const SirenAlertPayload({
    required this.data,
    this.title,
    this.body,
  });

  final Map<String, dynamic> data;
  final String? title;
  final String? body;

  factory SirenAlertPayload.fromRemoteMessage(RemoteMessage message) {
    final data = <String, dynamic>{};
    message.data.forEach((key, value) {
      data[key.toString()] = value?.toString();
    });

    final title =
        data['title']?.toString().trim().isNotEmpty == true ? data['title'] : null;
    final body = (data['message'] ?? data['body'])?.toString().trim().isNotEmpty ==
            true
        ? (data['message'] ?? data['body'])
        : null;

    return SirenAlertPayload(
      data: data,
      title: title?.toString() ?? message.notification?.title,
      body: body?.toString() ?? message.notification?.body,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'body': body,
        'data': data,
      };

  String encode() => jsonEncode(toJson());

  static SirenAlertPayload? tryDecode(String? raw) {
    final trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return null;

      final data = switch (decoded['data']) {
        Map<dynamic, dynamic>() =>
          decoded['data'].map((k, v) => MapEntry(k.toString(), v)),
        _ => <String, dynamic>{},
      };

      return SirenAlertPayload(
        data: Map<String, dynamic>.from(data),
        title: decoded['title']?.toString(),
        body: decoded['body']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
