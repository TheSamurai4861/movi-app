import 'dart:async';

import 'package:dio/dio.dart';

import 'package:movi/src/core/logging/logger.dart';

typedef TokenPredicate = bool Function(RequestOptions request);
typedef TokenLoader = FutureOr<String?> Function();

class AuthToken {
  const AuthToken({required this.value, this.scheme = 'Bearer'});

  final String value;
  final String scheme;

  String get headerValue => scheme.isEmpty ? value : '$scheme ${value.trim()}';
}

abstract class AuthTokenProvider {
  const AuthTokenProvider();

  FutureOr<AuthToken?> token(
    RequestOptions request, {
    bool forceRefresh = false,
  });
}

class MemoizedTokenProvider extends AuthTokenProvider {
  MemoizedTokenProvider({
    required this.loader,
    this.scheme = 'Bearer',
    TokenPredicate? appliesTo,
  }) : _appliesTo = appliesTo ?? _always;

  final TokenLoader loader;
  final String scheme;
  final TokenPredicate _appliesTo;

  AuthToken? _cached;
  bool _hasLoadedOnce = false;

  @override
  Future<AuthToken?> token(
    RequestOptions request, {
    bool forceRefresh = false,
  }) async {
    if (!_appliesTo(request)) return null;
    if (!forceRefresh) {
      if (_cached != null) return _cached;
      if (_hasLoadedOnce && _cached == null) return null;
    }

    final raw = (await loader())?.trim();
    _hasLoadedOnce = true;
    if (raw == null || raw.isEmpty) {
      _cached = null;
      return null;
    }

    _cached = AuthToken(value: raw, scheme: scheme);
    return _cached;
  }

  static bool _always(RequestOptions _) => true;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenProvider, this.logger, Dio? dio})
    : _dio = dio;

  final AuthTokenProvider tokenProvider;
  final AppLogger? logger;
  final Dio? _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.headers.containsKey('Authorization')) {
      handler.next(options);
      return;
    }

    try {
      final token = await tokenProvider.token(options);
      if (token != null) {
        options.headers['Authorization'] = token.headerValue;
      }
    } catch (e, st) {
      logger?.error('Unable to resolve auth token', e, st);
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry =
        err.response?.statusCode == 401 &&
        _dio != null &&
        err.requestOptions.extra['auth_retry'] != true;
    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    try {
      final refreshed = await tokenProvider.token(
        err.requestOptions,
        forceRefresh: true,
      );
      if (refreshed == null) {
        handler.next(err);
        return;
      }

      final retryOptions = err.requestOptions.copyWith(
        data: err.requestOptions.data,
        headers: Map<String, dynamic>.from(err.requestOptions.headers),
        queryParameters: Map<String, dynamic>.from(
          err.requestOptions.queryParameters,
        ),
      );
      retryOptions.headers['Authorization'] = refreshed.headerValue;
      retryOptions.extra = Map<String, dynamic>.from(err.requestOptions.extra)
        ..['auth_retry'] = true;

      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } catch (e, st) {
      logger?.error('Token refresh failed', e, st);
      handler.next(err);
    }
  }
}
