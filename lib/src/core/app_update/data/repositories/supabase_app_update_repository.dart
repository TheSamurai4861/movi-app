import 'dart:async';

import 'package:movi/src/core/app_update/data/datasources/app_update_cache_data_source.dart';
import 'package:movi/src/core/app_update/data/services/app_update_edge_service.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';
import 'package:movi/src/core/app_update/domain/repositories/app_update_repository.dart';
import 'package:movi/src/core/logging/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAppUpdateRepository implements AppUpdateRepository {
  const SupabaseAppUpdateRepository({
    required AppUpdateEdgeService remoteDataSource,
    required AppUpdateCacheDataSource cacheDataSource,
    AppLogger? logger,
  }) : _remoteDataSource = remoteDataSource,
       _cacheDataSource = cacheDataSource,
       _logger = logger;

  final AppUpdateEdgeService _remoteDataSource;
  final AppUpdateCacheDataSource _cacheDataSource;
  final AppLogger? _logger;

  @override
  Future<AppUpdateDecision> check(AppUpdateContext context) async {
    try {
      final remoteResponse = await _remoteDataSource.fetchDecision(context);
      await _cacheDataSource.write(remoteResponse);
      final decision = remoteResponse.toDecision();
      _logSuccess(decision, source: 'remote');
      return decision;
    } catch (error, stackTrace) {
      final cached = await _cacheDataSource.read();
      final cachedDecision = cached?.toDecision();
      if (_shouldUseCachedDecision(cachedDecision, context)) {
        final usableCachedDecision = cachedDecision!;
        _logger?.warn(
          '[AppUpdate] remote check failed, using cached decision '
          'status=${usableCachedDecision.status.name} '
          'reasonCode=${usableCachedDecision.reasonCode ?? 'n/a'}',
          category: 'app_update',
        );
        return usableCachedDecision;
      }

      if (_shouldFailOpen(error)) {
        final decision = AppUpdateDecision.allow(
          currentVersion: context.currentVersion,
          platform: context.platform,
          checkedAt: DateTime.now().toUtc(),
          reasonCode: _fallbackReasonCode(error),
          message: 'Remote app update check unavailable; startup allowed.',
          cacheTtl: Duration.zero,
        );
        _logger?.warn(
          '[AppUpdate] remote check failed open '
          'status=${decision.status.name} '
          'reasonCode=${decision.reasonCode ?? 'n/a'}',
          category: 'app_update',
        );
        return decision;
      }

      _logger?.error(
        '[AppUpdate] remote check failed without usable cache.',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  bool _shouldUseCachedDecision(
    AppUpdateDecision? decision,
    AppUpdateContext context,
  ) {
    if (decision == null) return false;
    if (decision.currentVersion != context.currentVersion) return false;
    if (decision.platform != context.platform) return false;

    if (decision.isBlocking) {
      return true;
    }

    final age = DateTime.now().toUtc().difference(decision.checkedAt.toUtc());
    return age <= decision.cacheTtl;
  }

  bool _shouldFailOpen(Object error) {
    if (error is FunctionException) {
      return error.status >= 500;
    }
    if (error is TimeoutException) {
      return true;
    }

    return _looksLikeNetworkError(error);
  }

  String _fallbackReasonCode(Object error) {
    if (error is FunctionException) {
      return error.status >= 500
          ? 'app_update_remote_server_error'
          : 'app_update_remote_function_error';
    }
    if (error is TimeoutException) {
      return 'app_update_remote_timeout';
    }
    if (_looksLikeNetworkError(error)) {
      return 'app_update_remote_network_error';
    }

    return 'app_update_remote_failed_open';
  }

  bool _looksLikeNetworkError(Object error) {
    final errorType = error.runtimeType.toString();
    return errorType.contains('SocketException') ||
        errorType.contains('_ClientSocketException') ||
        errorType.contains('ClientException');
  }

  void _logSuccess(AppUpdateDecision decision, {required String source}) {
    final level = decision.isBlocking ? _logger?.warn : _logger?.info;
    level?.call(
      '[AppUpdate] source=$source status=${decision.status.name} '
      'version=${decision.currentVersion} platform=${decision.platform} '
      'reasonCode=${decision.reasonCode ?? 'n/a'}',
      category: 'app_update',
    );
  }
}
