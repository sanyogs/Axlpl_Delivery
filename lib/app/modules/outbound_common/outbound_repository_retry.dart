import 'package:axlpl_delivery/app/data/networking/api_exception.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';

/// Tries API calls in order; returns first success or the last response.
Future<APIResponse<dynamic>> outboundFirstSuccess(
  List<Future<APIResponse<dynamic>> Function()> attempts,
) async {
  APIResponse<dynamic>? last;
  for (final attempt in attempts) {
    final r = await attempt();
    last = r;
    final ok = r.when(success: (_) => true, error: (_) => false);
    if (ok) return r;
  }
  return last ??
      APIResponse.error(AppException.errorWithMessage('Request failed'));
}

bool outboundIsBenignDuplicate(String? message) {
  final m = (message ?? '').toLowerCase();
  return m.contains('already scanned') || m.contains('already picked');
}
