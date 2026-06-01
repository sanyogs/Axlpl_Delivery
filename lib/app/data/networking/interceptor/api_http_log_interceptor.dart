import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Logs every Dio request and response body for debugging.
///
/// **Enabled when:**
/// - [kDebugMode] is `true`, **or**
/// - built with `--dart-define=API_HTTP_LOG=true` (also works in profile/release).
///
/// **Redaction:** `Authorization` header values, common secret form keys (`password`,
/// `otp`, `fcm_token`, `token`, etc.) are masked in logs. Response bodies are truncated
/// past [_maxResponseChars] to avoid huge HTML/JSON flooding the console.
class ApiHttpLogInterceptor extends Interceptor {
  ApiHttpLogInterceptor({this.maxResponseChars = 65536});

  static const bool _logFromDefine = bool.fromEnvironment(
    'API_HTTP_LOG',
    defaultValue: false,
  );

  /// Whether HTTP logging is active for this build.
  static bool get enabled => kDebugMode || _logFromDefine;

  final int maxResponseChars;

  static const String _logName = 'ApiHttp';

  static Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> h) {
    final out = <String, dynamic>{};
    h.forEach((k, v) {
      final lk = k.toLowerCase();
      if (lk == 'authorization') {
        final s = v?.toString() ?? '';
        out[k] = s.length > 24 ? '${s.substring(0, 20)}…(redacted)' : '***(redacted)';
      } else {
        out[k] = v;
      }
    });
    return out;
  }

  static bool _isSensitiveKey(String key) {
    final lk = key.toLowerCase();
    return lk.contains('password') ||
        lk == 'otp' ||
        lk.contains('token') ||
        lk == 'fcm_token' ||
        lk.contains('secret') ||
        lk.contains('authorization');
  }

  static dynamic _sanitizeData(dynamic data) {
    if (data is Map) {
      final m = <String, dynamic>{};
      data.forEach((k, v) {
        final ks = k.toString();
        if (_isSensitiveKey(ks)) {
          m[ks] = '***(redacted)';
        } else if (v is Map || v is List) {
          m[ks] = _sanitizeData(v);
        } else {
          m[ks] = v;
        }
      });
      return m;
    }
    if (data is List) {
      return data.map(_sanitizeData).toList();
    }
    if (data is FormData) {
      return {
        'type': 'FormData',
        'fields': data.fields
            .map((e) => {
                  'key': e.key,
                  'value': _isSensitiveKey(e.key) ? '***(redacted)' : e.value,
                })
            .toList(),
        'fileKeys': data.files.map((e) => e.key).toList(),
      };
    }
    return data;
  }

  /// Writes to DevTools (`ApiHttp`) and `flutter run` console so every call is visible.
  static void _emit(String message, {int level = 800}) {
    developer.log(message, name: _logName, level: level);
    if (kDebugMode || _logFromDefine) {
      debugPrint('[$_logName] $message');
    }
  }

  static String _formatPayload(dynamic data, {required int maxChars}) {
    if (data == null) return 'null';
    if (data is String) {
      if (data.length > maxChars) {
        return '${data.substring(0, maxChars)}\n… (${data.length - maxChars} more chars)';
      }
      return data;
    }
    try {
      final s = const JsonEncoder.withIndent('  ').convert(data);
      if (s.length > maxChars) {
        return '${s.substring(0, maxChars)}\n… (${s.length - maxChars} more chars)';
      }
      return s;
    } catch (_) {
      return data.toString();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) {
      super.onRequest(options, handler);
      return;
    }
    final buf = StringBuffer()
      ..writeln('── REQUEST ${options.method} ${options.uri}')
      ..writeln('headers: ${_formatPayload(_sanitizeHeaders(options.headers.map((k, v) => MapEntry(k, v?.toString() ?? ''))), maxChars: 8000)}')
      ..writeln('query: ${_formatPayload(options.queryParameters, maxChars: 8000)}')
      ..writeln('data: ${_formatPayload(_sanitizeData(options.data), maxChars: 16000)}');
    _emit(buf.toString());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (!enabled) {
      super.onResponse(response, handler);
      return;
    }
    final buf = StringBuffer()
      ..writeln('── RESPONSE ${response.statusCode} ${response.requestOptions.uri}')
      ..writeln(_formatPayload(response.data, maxChars: maxResponseChars));
    _emit(buf.toString());
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled) {
      super.onError(err, handler);
      return;
    }
    final buf = StringBuffer()
      ..writeln('── ERROR ${err.requestOptions.method} ${err.requestOptions.uri}')
      ..writeln('type: ${err.type}')
      ..writeln('message: ${err.message}');
    final resp = err.response;
    if (resp != null) {
      buf.writeln('status: ${resp.statusCode}');
      buf.writeln(_formatPayload(resp.data, maxChars: maxResponseChars));
    }
    _emit(buf.toString(), level: 1000);
    handler.next(err);
  }
}
