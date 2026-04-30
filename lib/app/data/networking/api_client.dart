import 'dart:developer';
import 'dart:io';
import 'package:axlpl_delivery/app/data/networking/api_exception.dart';
import 'package:axlpl_delivery/app/data/networking/api_response.dart';
import 'package:axlpl_delivery/common_widget/force_update_dialog.dart';
import 'package:axlpl_delivery/app/data/networking/interceptor/dio_connectivity_request_retry.dart';
import 'package:axlpl_delivery/app/data/networking/interceptor/retry_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApiClient {
  late Dio _dio;
  final String baseUrl = 'https://my.axlpl.com/messenger/services_v8/';
  late final Future<String> _appVersionFuture = _loadAppVersion();

  ApiClient() {
    _dio = Dio();
    _dio.options.baseUrl = baseUrl;
    _dio.options.sendTimeout = Duration(seconds: 5);
    _dio.options.connectTimeout = Duration(seconds: 5);
    _dio.options.receiveTimeout = Duration(seconds: 5);
    _dio.interceptors.add(
      RetryOnConnectionChangeInterceptor(
        requestRetrier: DioConnectivityRequestRetrier(
          dio: _dio,
          connectivity: Connectivity(),
        ),
      ),
    );
    // if (kDebugMode) {
    //   _dio.interceptors.add(TalkerDioLogger(
    //     settings: const TalkerDioLoggerSettings(
    //       printErrorHeaders: true,
    //       printRequestHeaders: true,
    //       printResponseData: true,
    //       printRequestData: true,
    //       printResponseHeaders: true,
    //       printResponseMessage: true,
    //       printErrorMessage: true,
    //       printErrorData: true,
    //     ),
    //   )
    //
    //       // PrettyDioLogger(
    //       //   requestHeader: true,
    //       //   requestBody: true,
    //       //   responseBody: true,
    //       //   responseHeader: false,
    //       //   error: true,
    //       //   compact: true,
    //       //   maxWidth: 90,
    //       // ),
    //       );
    // }
  }

  Future<String> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      debugPrint('Unable to read app version: $e');
      return '0.0.0';
    }
  }

  String get _appPlatform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }

  Future<Map<String, String>> _buildHeaders({
    required String content,
    String? token,
  }) async {
    final appVersion = await _appVersionFuture;
    final appPlatform = _appPlatform;

    return {
      'accept': '*/*',
      'Content-Type': content,
      'X-App-Version': appVersion,
      'X-App-Platform': appPlatform,
      'X-Platform': appPlatform,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic>? _appendPlatformToQuery(Map<String, dynamic>? query) {
    if (query == null) {
      return {'platform': _appPlatform};
    }
    final updated = <String, dynamic>{...query};
    updated.putIfAbsent('platform', () => _appPlatform);
    return updated;
  }

  dynamic _appendPlatformToBody(dynamic body) {
    if (body is Map) {
      final updated = <String, dynamic>{};
      body.forEach((key, value) {
        updated[key.toString()] = value;
      });
      updated.putIfAbsent('platform', () => _appPlatform);
      return updated;
    }

    if (body is FormData) {
      final hasPlatform = body.fields.any((field) => field.key == 'platform');
      if (!hasPlatform) {
        body.fields.add(MapEntry('platform', _appPlatform));
      }
      return body;
    }

    return body;
  }

  bool _isTruthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' ||
          normalized == 'true' ||
          normalized == 'yes' ||
          normalized == 'y';
    }
    return false;
  }

  Map<String, dynamic> _asStringKeyedMap(dynamic source) {
    final map = <String, dynamic>{};
    if (source is Map) {
      source.forEach((key, value) {
        map[key.toString()] = value;
      });
    }
    return map;
  }

  APIResponse? _handleForceUpdateResponse(dynamic payload) {
    final topLevel = _asStringKeyedMap(payload);
    if (topLevel.isEmpty) return null;

    final nestedData = _asStringKeyedMap(topLevel['data']);

    dynamic pick(List<String> keys) {
      for (final key in keys) {
        if (topLevel.containsKey(key) && topLevel[key] != null) {
          return topLevel[key];
        }
      }
      for (final key in keys) {
        if (nestedData.containsKey(key) && nestedData[key] != null) {
          return nestedData[key];
        }
      }
      return null;
    }

    final status = pick(['status'])?.toString().trim().toLowerCase();
    final shouldForceUpdate = _isTruthy(pick(['force_update', 'forceUpdate']));
    if (status != 'fail' || !shouldForceUpdate) {
      return null;
    }

    final message = pick(['message'])?.toString().trim();
    final updateUrl = pick(['update_url', 'updateUrl'])?.toString().trim();

    showForceUpdateDialog(
      message: message,
      updateUrl: updateUrl,
    );

    return APIResponse.error(
      AppException.errorWithMessage(
        (message != null && message.isNotEmpty)
            ? message
            : 'Please update your app to continue.',
      ),
    );
  }

  Future<APIResponse> post(
    String path,
    dynamic body, {
    String? newBaseUrl,
    String? token,
    Map<String, String?>? query,
    ContentType contentType = ContentType.urlEncoded,
  }) async {
    // ✅ Step 1: Check Internet Connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return APIResponse.error(AppException.connectivity());
    }

    // ✅ Step 2: ruct URL
    String url = newBaseUrl != null ? newBaseUrl + path : baseUrl + path;
    final requestBody = _appendPlatformToBody(body);
    final queryParameters = _appendPlatformToQuery(
      query == null ? null : Map<String, dynamic>.from(query),
    );

    // ✅ Step 3: Define Content Type
    String content;
    switch (contentType) {
      case ContentType.json:
        content = 'application/json';
        break;
      case ContentType.multipart:
        content = 'multipart/form-data';
        break;
      default:
        content = 'application/x-www-form-urlencoded';
    }

    try {
      // ✅ Step 4: Define Headers
      final headers = await _buildHeaders(content: content, token: token);

      // ✅ Step 5: Make the API Request
      final response = await _dio.post(
        url,
        data: requestBody,
        queryParameters: queryParameters,
        options: Options(
          contentType: contentType == ContentType.multipart
              ? 'multipart/form-data'
              : contentType == ContentType.json
                  ? Headers.jsonContentType
                  : Headers.formUrlEncodedContentType,
          validateStatus: (status) => true,
          headers: headers,
        ),
      );

      // ✅ Step 6: Handle Response Codes
      if (response.statusCode == null) {
        // debugPrint('Status Code is Null. Response: ${response.toString()}');
        return APIResponse.error(AppException.connectivity());
      }

      final forceUpdateResponse = _handleForceUpdateResponse(response.data);
      if (forceUpdateResponse != null) {
        return forceUpdateResponse;
      }

      if (response.statusCode! < 300) {
        return response.data['data'] != null
            ? APIResponse.success(response.data['data'])
            : APIResponse.success(response.data);
      } else {
        return _handleErrorResponse(response);
      }
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      return APIResponse.error(AppException.errorWithMessage(e.toString()));
    }
  }

  /// ✅ Handles HTTP Errors based on status codes
  APIResponse _handleErrorResponse(Response response) {
    switch (response.statusCode) {
      case 401:
        return APIResponse.error(AppException.unauthorized());
      case 403:
        return APIResponse.error(AppException.forbidden());
      case 404:
        return APIResponse.error(AppException.notFound());
      case 502:
        return APIResponse.error(AppException.badGateway());
      case 500:
        return APIResponse.error(AppException.serverError());
      default:
        final message = response.data['message'] as String?;
        return message != null
            ? APIResponse.error(AppException.errorWithMessage(message))
            : APIResponse.error(AppException.error());
    }
  }

  /// ✅ Handles DioExceptions like timeouts, no internet, etc.
  APIResponse _handleDioException(DioException e) {
    debugPrint('DioException: ${e.toString()}');
    // debugPrint('Response Data: ${e.response?.data}');

    if (e.error is SocketException) {
      return APIResponse.error(AppException.connectivity());
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return APIResponse.error(AppException.connectivity());
    }

    final message = e.response?.data['message'] as String?;
    return message != null
        ? APIResponse.error(AppException.errorWithMessage(message))
        : APIResponse.error(AppException.errorWithMessage(e.message ?? ''));
  }

  Future<APIResponse> get(
    String path, {
    String? newBaseUrl,
    String? token,
    Map<String, dynamic>? query,
    ContentType contentType = ContentType.urlEncoded,
  }) async {
    // Check for network connectivity with potential error handling
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return APIResponse.error(AppException.connectivity());
      }
    } catch (e) {
      log("Connectivity check failed: ${e.toString()}");
      return APIResponse.error(
          AppException.errorWithMessage("Connectivity check failed"));
    }

    // Determine the URL to use
    String url = newBaseUrl != null ? newBaseUrl + path : baseUrl + path;
    final queryParameters = _appendPlatformToQuery(query);

    // Simplify content-type assignment
    final content = contentType == ContentType.json
        ? 'application/json; charset=utf-8'
        : 'application/x-www-form-urlencoded';

    try {
      // Setup headers with an optional authorization token
      final headers = await _buildHeaders(content: content, token: token);

      // Perform the GET request
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(validateStatus: (status) => true, headers: headers),
      );

      // Handle response based on status code
      if (response.statusCode == null) {
        return APIResponse.error(AppException.connectivity());
      }

      final forceUpdateResponse = _handleForceUpdateResponse(response.data);
      if (forceUpdateResponse != null) {
        return forceUpdateResponse;
      }

      if (response.statusCode! < 300) {
        return response.data['data'] != null
            ? APIResponse.success(response.data['data'])
            : APIResponse.success(response.data);
      } else {
        switch (response.statusCode) {
          case 401:
            return APIResponse.error(AppException.unauthorized());
          case 403:
            return APIResponse.error(AppException.forbidden());
          case 404:
            return APIResponse.error(AppException.notFound());
          case 502:
            return APIResponse.error(AppException.badGateway());
          case 500:
            return APIResponse.error(AppException.serverError());
          default:
            final message = response.data['message'] as String?;
            return message != null
                ? APIResponse.error(AppException.errorWithMessage(message))
                : APIResponse.error(AppException.error());
        }
      }
    } on DioException catch (e) {
      // Specific catch blocks with logging
      if (e.error is SocketException) {
        log("SocketException: ${e.message}");
        return APIResponse.error(AppException.connectivity());
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        log("TimeoutException: ${e.message}");
        return APIResponse.error(AppException.connectivity());
      }

      if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        log("BadResponseException: ${e.message}, statusCode: $statusCode");
        final errorMessage =
            e.response?.data['message'] as String? ?? 'Something went wrong.';
        return APIResponse.error(AppException.errorWithMessage(errorMessage));
      }

      if (e.type == DioExceptionType.cancel) {
        log("Request was cancelled: ${e.message}");
        // Return an error or handle it as needed
      }

      log("DioException: ${e.message}");
      return APIResponse.error(AppException.error());
    } catch (e) {
      // Capture any unexpected exceptions
      log("Unexpected error: ${e.toString()}");
      return APIResponse.error(
          AppException.errorWithMessage("Unexpected error occurred"));
    }
  }

  Future<Response<dynamic>?> getRaw(
    String path, {
    String? newBaseUrl,
    String? token,
    Map<String, dynamic>? query,
    ContentType contentType = ContentType.urlEncoded,
  }) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return null;
      }
    } catch (e) {
      log("Connectivity check failed: ${e.toString()}");
      return null;
    }

    final url = newBaseUrl != null ? newBaseUrl + path : baseUrl + path;
    final queryParameters = _appendPlatformToQuery(query);
    final content = contentType == ContentType.json
        ? 'application/json; charset=utf-8'
        : 'application/x-www-form-urlencoded';

    try {
      final headers = await _buildHeaders(content: content, token: token);
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: Options(validateStatus: (status) => true, headers: headers),
      );
      _handleForceUpdateResponse(response.data);
      return response;
    } on DioException catch (e) {
      log("Raw GET DioException: ${e.message}");
      _handleForceUpdateResponse(e.response?.data);
      return e.response;
    } catch (e) {
      log("Raw GET unexpected error: ${e.toString()}");
      return null;
    }
  }
}

enum ContentType { json, urlEncoded, multipart }
