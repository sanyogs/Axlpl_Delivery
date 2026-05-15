/// Common Services V8 JSON envelope: `status`, `message`, `data`, optional `error_code`.
///
/// `ApiClient` returns `APIResponse.success` with the **inner** `data` payload only when
/// HTTP succeeds and top-level `status` is not `fail`. Top-level `fail` is mapped to
/// `APIResponse.error` (see `_handleBusinessStatusFailure` in `api_client.dart`). Use this class when parsing
/// nested maps or raw JSON (e.g. capture script output). Sample payloads:
/// `docs/outbound_v8_api_capture.json`.
class OutboundApiEnvelope {
  OutboundApiEnvelope({
    required this.status,
    required this.message,
    this.data,
    this.errorCode,
    this.raw,
  });

  final String? status;
  final String? message;
  final dynamic data;
  final int? errorCode;
  final Map<String, dynamic>? raw;

  bool get isSuccess => (status ?? '').toLowerCase() == 'success';

  factory OutboundApiEnvelope.fromDynamic(dynamic source) {
    if (source is! Map) {
      return OutboundApiEnvelope(
        status: null,
        message: 'Non-map response',
        data: source,
        raw: null,
      );
    }
    final m = Map<String, dynamic>.from(
      source.map((k, v) => MapEntry(k.toString(), v)),
    );
    final ec = m['error_code'];
    return OutboundApiEnvelope(
      status: m['status']?.toString(),
      message: m['message']?.toString(),
      data: m['data'],
      errorCode: ec is int ? ec : int.tryParse(ec?.toString() ?? ''),
      raw: m,
    );
  }
}
