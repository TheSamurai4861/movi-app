import 'package:dio/dio.dart';
import 'package:movi/src/core/logging/logger.dart';

void configureDioProxyFromEnvironment(Dio dio, {AppLogger? logger}) {
  // No-op on non-IO platforms (e.g. Web).
}
