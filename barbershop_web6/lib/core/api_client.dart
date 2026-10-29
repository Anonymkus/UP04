import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<bool> Function()? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  void log(RequestOptions options, Object status) {
    if (kDebugMode) {
      debugPrint('[API] ${options.method} ${options.uri} → $status');
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        for (final key in ['__fail', '__delay']) {
          final value = Uri.base.queryParameters[key];
          if (value != null) options.queryParameters[key] = value;
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        log(response.requestOptions, status);
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.error is! ApiException) {
          log(
            error.requestOptions,
            error.response?.statusCode ?? error.type.name,
          );
        }
        final options = error.requestOptions;
        final canRefresh =
            error.response?.statusCode == 401 &&
            !options.path.contains('/auth/') &&
            options.extra['retried'] != true &&
            onUnauthorized != null;
        if (canRefresh && await onUnauthorized()) {
          options.extra['retried'] = true;
          try {
            return handler.resolve(await dio.fetch(options));
          } on DioException catch (e) {
            return handler.next(e);
          }
        }
        return handler.next(error);
      },
    ),
  );
  return dio;
}
