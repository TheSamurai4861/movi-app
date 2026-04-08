import 'package:movi/src/core/app_update/data/datasources/app_update_cache_data_source.dart';
import 'package:movi/src/core/app_update/data/services/app_update_edge_service.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_context.dart';
import 'package:movi/src/core/app_update/domain/entities/app_update_decision.dart';
import 'package:movi/src/core/app_update/domain/repositories/app_update_repository.dart';
import 'package:movi/src/core/logging/logger.dart';

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