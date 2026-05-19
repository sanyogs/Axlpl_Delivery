import 'dart:convert';

/// Helpers for outbound V8 JSON payloads and typed outbound models.
class OutboundDataParse {
  OutboundDataParse._();

  static String pretty(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  /// True when [pretty] would show a large HTML or plain body (reports / print).
  static bool isNonJsonBody(dynamic data) {
    if (data is String) {
      final t = data.trim();
      if (t.length > 4000) return true;
      final lower = t.toLowerCase();
      if (lower.startsWith('<!doctype') || lower.startsWith('<html')) {
        return true;
      }
      if (t.startsWith('<') && t.contains('</')) return true;
    }
    return false;
  }

  static List<dynamic> asList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['data', 'list', 'items', 'rows', 'logs', 'bags', 'manifests', 'linehauls']) {
        final v = data[key];
        if (v is List) return v;
      }
    }
    return [];
  }

  /// Maps extracted from list payloads (uses [asList] unwrapping).
  static List<Map<String, dynamic>> asMapList(dynamic data) {
    return asList(data)
        .whereType<Map>()
        .map(asStringKeyedMap)
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  /// Typed list rows from API `data` (list or map with nested list keys).
  static List<T> mapListFromDynamic<T>(
    dynamic data,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    return asMapList(data).map(fromJson).toList();
  }

  /// JSON object as [Map] with string keys, or `null` if [data] is not a map.
  static Map<String, dynamic>? asStringKeyedMap(dynamic data) {
    if (data is! Map) return null;
    return Map<String, dynamic>.from(
      data.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  /// First non-empty string value for any of [keys] on [map].
  static String? firstNonEmptyString(Map<String, dynamic>? map, List<String> keys) {
    if (map == null) return null;
    for (final k in keys) {
      final v = map[k];
      if (v == null) continue;
      final s = v.toString().trim();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  /// Optional string field; empty strings become `null`.
  static String? optionalString(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Optional int field from numeric or string JSON values.
  static int? optionalInt(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString().trim());
  }

  /// Parses `"0"`/`"1"` or bool flags used by outbound V8 list rows.
  static bool? boolFromZeroOne(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().trim().toLowerCase();
    if (s == '0' || s == 'false') return false;
    if (s == '1' || s == 'true') return true;
    return null;
  }
}
