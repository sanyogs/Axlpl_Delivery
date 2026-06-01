import 'dart:io';

import 'package:axlpl_delivery/app/data/networking/interceptor/dio_connectivity_request_retry.dart';
import 'package:dio/dio.dart';

class RetryOnConnectionChangeInterceptor extends Interceptor {
  RetryOnConnectionChangeInterceptor({
    required this.requestRetrier,
  });

  final DioConnectivityRequestRetrier requestRetrier;

  static const Duration _retryWaitTimeout = Duration(seconds: 20);

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      try {
        final response = await requestRetrier
            .scheduleRequestRetry(err.requestOptions)
            .timeout(_retryWaitTimeout);
        return handler.resolve(response);
      } catch (_) {
        // Forward the original error when retry fails or times out.
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout &&
        err.error != null &&
        err.error is SocketException;
  }
}
