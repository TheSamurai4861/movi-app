import 'package:dio/dio.dart';

import 'package:movi/src/core/logging/logger.dart';

class TelemetryInterceptor extends Interceptor {
  TelemetryInterceptor({required this.logger, this.enabled = true, this.thresholdMs = 400});

  final AppLogger logger;
  final bool enabled;
  final int thresholdMs;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      options.extra['request-start'] = DateTime.now().millisecondsSinceEpoch;
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logLatency(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logLatency(err.requestOptions, err.response?.statusCode);
    handler.next(err);
  }

  void _logLatency(RequestOptions options, int? statusCode) {
    if (!enabled) return;
    final start = options.extra['request-start'] as int?;
    if (start == null) return;
    final duration = DateTime.now().millisecondsSinceEpoch - start;
    if (duration >= thresholdMs) {
      logger.debug(
        '[HTTP] ${options.method} ${options.path} ($statusCode) - ${duration}ms',
      );
    }
    options.extra.remove('request-start');
  }
}
