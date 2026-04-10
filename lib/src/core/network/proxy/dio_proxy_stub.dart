import 'package:dio/dio.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/proxy/proxy_configuration.dart';

void configureDioProxyFromEnvironment(Dio dio, {AppLogger? logger}) {
  // No-op on non-IO platforms (e.g. Web).
}

void configureDioProxy(
  Dio dio, {
  required DioProxyConfiguration configuration,
  AppLogger? logger,
}) {
  // No-op on non-IO platforms (e.g. Web).
}
