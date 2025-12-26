import 'dart:io';

import 'package:movi/src/core/logging/logger.dart';
import 'package:movi/src/core/network/proxy/http_overrides_stub.dart'
    if (dart.library.io) 'package:movi/src/core/network/proxy/http_overrides_io.dart'
    as impl;

/// Configure a global [HttpOverrides] from compile-time defines (optional).
///
/// This is required for libraries that don't use Dio (e.g. Supabase / `http`)
/// when running behind a proxy.
///
/// Supported defines (via `--dart-define` or `--dart-define-from-file`):
/// - `HTTP_PROXY`  (e.g. `http://user:pass@proxy.company.com:8080`)
/// - `HTTPS_PROXY` (defaults to `HTTP_PROXY` when empty)
/// - `NO_PROXY`    (comma-separated hosts/domain suffixes)
void configureHttpOverridesFromEnvironment({AppLogger? logger}) {
  HttpOverrides.global = impl.createHttpOverridesFromEnvironment(
    logger: logger,
  );
}
