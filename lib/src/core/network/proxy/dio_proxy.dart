import 'package:dio/dio.dart';
import 'package:movi/src/core/logging/logger.dart';

import 'package:movi/src/core/network/proxy/dio_proxy_stub.dart'
    if (dart.library.io) 'package:movi/src/core/network/proxy/dio_proxy_io.dart'
    as impl;

/// Configure Dio proxy settings from compile-time defines (optional).
///
/// Supported defines (via `--dart-define` or `--dart-define-from-file`):
/// - `HTTP_PROXY`  (e.g. `http://user:pass@proxy.company.com:8080`)
/// - `HTTPS_PROXY` (defaults to `HTTP_PROXY` when empty)
/// - `NO_PROXY`    (comma-separated hosts/domain suffixes)
void configureDioProxyFromEnvironment(Dio dio, {AppLogger? logger}) {
  impl.configureDioProxyFromEnvironment(dio, logger: logger);
}
