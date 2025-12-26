import 'dart:async';

import 'package:dio/dio.dart';

import 'package:movi/src/core/logging/logger.dart';

typedef RetryEvaluator = bool Function(DioException exception);

class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required Dio dio,
    this.maxAttempts = 3,
    this.delay = const Duration(milliseconds: 500),
    this.retryEvaluator,
    this.logger,
  }) : _dio = dio;

  final Dio _dio;
  final int maxAttempts;
  final Duration delay;
  final RetryEvaluator? retryEvaluator;
  final AppLogger? logger;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    var attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;
    final shouldRetry = _shouldRetry(err) && attempt < maxAttempts;
    final cancelToken = err.requestOptions.cancelToken;

    if (cancelToken?.isCancelled == true) {
      handler.next(err);
      return;
    }

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    attempt += 1;
    err.requestOptions.extra['retry_attempt'] = attempt;
    logger?.warn('Retrying ${err.requestOptions.uri} (attempt $attempt)');

    await Future.delayed(delay * attempt);

    try {
      final requestOptions = err.requestOptions.copyWith(
        data: err.requestOptions.data,
        headers: Map<String, dynamic>.from(err.requestOptions.headers),
        queryParameters: Map<String, dynamic>.from(
          err.requestOptions.queryParameters,
        ),
      )..cancelToken = cancelToken;

      final response = await _dio.fetch(requestOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  bool _shouldRetry(DioException error) {
    if (retryEvaluator != null) return retryEvaluator!(error);
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = error.response?.statusCode ?? 0;
    return status == 429 || status >= 500;
  }
}
