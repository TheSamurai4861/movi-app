import 'package:flutter/material.dart';
import 'package:movi/src/core/logging/logging_service.dart';

class ImagePipelineTelemetry {
  const ImagePipelineTelemetry._();

  static int _attempt = 0;
  static int _cacheSuccess = 0;
  static int _fallbackSuccess = 0;
  static int _failure = 0;

  static void trackAttempt(BuildContext context, Uri uri) {
    _attempt++;
    _log('image_load_attempt_total', context, uri, <String, Object?>{
      'count': _attempt,
    });
  }

  static void trackCacheSuccess(BuildContext context, Uri uri) {
    _cacheSuccess++;
    _log('image_load_cache_success_total', context, uri, <String, Object?>{
      'count': _cacheSuccess,
    });
  }

  static void trackFallbackSuccess(BuildContext context, Uri uri) {
    _fallbackSuccess++;
    _log('image_load_fallback_success_total', context, uri, <String, Object?>{
      'count': _fallbackSuccess,
    });
  }

  static void trackFailure(
    BuildContext context,
    Uri uri, {
    required String errorKind,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _failure++;
    _log(
      'image_load_failure_total',
      context,
      uri,
      <String, Object?>{'count': _failure, 'error_kind': errorKind},
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    String metric,
    BuildContext context,
    Uri uri,
    Map<String, Object?> extra, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final screen =
        ModalRoute.of(context)?.settings.name?.trim().isNotEmpty == true
        ? ModalRoute.of(context)!.settings.name!.trim()
        : 'unknown';
    final host = uri.host.toLowerCase();
    final sourceType = host.contains('tmdb') ? 'tmdb' : 'other';
    final payload = <String, Object?>{
      'metric': metric,
      'screen': screen,
      'source_type': sourceType,
      ...extra,
    };
    final message = payload.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    LoggingService.log(
      '[ImagePipeline] $message',
      category: 'image_pipeline',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
