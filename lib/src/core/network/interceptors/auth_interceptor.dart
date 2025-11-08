import 'dart:async';

import 'package:dio/dio.dart';

typedef TokenResolver = FutureOr<String?> Function();

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokenResolver});

  final TokenResolver tokenResolver;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await tokenResolver();
    if (token != null && token.isNotEmpty) {
      options.headers.putIfAbsent('Authorization', () => 'Bearer $token');
    }
    handler.next(options);
  }
}
