import 'package:axlpl_delivery/app/data/models/outbound_data_parse.dart';

/// Standard outbound mutation envelope: `{ status, message, data, error_code }`.
class OutboundApiEnvelope {
  const OutboundApiEnvelope({
    this.status,
    this.message,
    this.data,
    this.errorCode,
  });

  final String? status;
  final String? message;
  final dynamic data;
  final int? errorCode;

  bool get isSuccess => status?.trim().toLowerCase() == 'success';

  bool get isFail {
    final s = status?.trim().toLowerCase();
    return s == 'fail' || s == 'error';
  }

  factory OutboundApiEnvelope.fromJson(Map<String, dynamic> json) {
    return OutboundApiEnvelope(
      status: OutboundDataParse.optionalString(json, 'status'),
      message: OutboundDataParse.optionalString(json, 'message'),
      data: json['data'],
      errorCode: OutboundDataParse.optionalInt(json, 'error_code'),
    );
  }

  factory OutboundApiEnvelope.fromDynamic(dynamic payload) {
    final map = OutboundDataParse.asStringKeyedMap(payload);
    if (map != null) return OutboundApiEnvelope.fromJson(map);
    return OutboundApiEnvelope(data: payload);
  }

  Map<String, dynamic> toJson() => {
        if (status != null) 'status': status,
        if (message != null) 'message': message,
        if (data != null) 'data': data,
        if (errorCode != null) 'error_code': errorCode,
      };
}
