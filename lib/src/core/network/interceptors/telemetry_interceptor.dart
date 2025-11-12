import 'package:dio/dio.dart';

import '../../utils/logger.dart';

class TelemetryInterceptor extends Interceptor {
  TelemetryInterceptor({required this.logger});

  final AppLogger logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['request-start'] = DateTime.now().millisecondsSinceEpoch;
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
    final start = options.extra['request-start'] as int?;
    if (start == null) return;
    final duration = DateTime.now().millisecondsSinceEpoch - start;
    logger.debug(
      '[HTTP] ${options.method} ${options.path} ($statusCode) - ${duration}ms',
    );
    options.extra.remove('request-start');
  }
}
