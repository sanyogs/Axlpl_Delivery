import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';

class SirenAlertAction {
  const SirenAlertAction({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
      };

  factory SirenAlertAction.fromJson(Map<dynamic, dynamic> json) {
    return SirenAlertAction(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}

class SirenAlertPayload {
  const SirenAlertPayload({
    required this.data,
    this.title,
    this.body,
    this.actions = const <SirenAlertAction>[],
  });

  final Map<String, dynamic> data;
  final String? title;
  final String? body;
  final List<SirenAlertAction> actions;

  factory SirenAlertPayload.fromRemoteMessage(
    RemoteMessage message, {
    String? titleOverride,
    String? bodyOverride,
    List<SirenAlertAction> actions = const <SirenAlertAction>[],
  }) {
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
      title: titleOverride?.toString().trim().isNotEmpty == true
          ? titleOverride!.toString().trim()
          : (title?.toString() ?? message.notification?.title),
      body: bodyOverride?.toString().trim().isNotEmpty == true
          ? bodyOverride!.toString().trim()
          : (body?.toString() ?? message.notification?.body),
      actions: actions,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'body': body,
        'data': data,
        'actions': actions.map((action) => action.toJson()).toList(),
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

      final actions = <SirenAlertAction>[];
      final rawActions = decoded['actions'];
      if (rawActions is List) {
        for (final item in rawActions) {
          if (item is Map) {
            actions.add(SirenAlertAction.fromJson(item));
          }
        }
      }

      return SirenAlertPayload(
        data: Map<String, dynamic>.from(data),
        title: decoded['title']?.toString(),
        body: decoded['body']?.toString(),
        actions: actions,
      );
    } catch (_) {
      return null;
    }
  }
}
