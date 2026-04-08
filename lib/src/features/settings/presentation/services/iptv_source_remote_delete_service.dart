import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';

/// Outcome of the best-effort cloud cleanup that follows a local source removal.
///
/// `deleted` and `skippedNotFound` confirm that the current account no longer
/// has a matching remote row to rehydrate. The remaining statuses mean the
/// local delete succeeded, but the source may reappear after reconnect while
/// the cloud row still exists.
enum RemoteIptvDeleteStatus {
  deleted,
  skippedNoSession,
  skippedRepositoryUnavailable,
  skippedNotFound,
  failed,
}

extension RemoteIptvDeleteStatusX on RemoteIptvDeleteStatus {
  bool get remoteDeletionConfirmed =>
      this == RemoteIptvDeleteStatus.deleted ||
      this == RemoteIptvDeleteStatus.skippedNotFound;

  bool get mayReappearAfterReconnect => !remoteDeletionConfirmed;
}

typedef LoadRemoteIptvSources =
    Future<List<SupabaseIptvSourceEntity>> Function({
      required String accountId,
    });
typedef DeleteRemoteIptvSource =
    Future<void> Function({required String id, required String accountId});

/// Best-effort cloud cleanup paired with a local source deletion.
///
/// If the returned status has [RemoteIptvDeleteStatusX.mayReappearAfterReconnect]
/// set to `true`, the source can still be restored later from Supabase for the
/// current authenticated account.
class IptvSourceRemoteDeleteService {
  const IptvSourceRemoteDeleteService({
    required LoadRemoteIptvSources loadSources,
    required DeleteRemoteIptvSource deleteSource,
  }) : _loadSources = loadSources,
       _deleteSource = deleteSource;

  final LoadRemoteIptvSources _loadSources;
  final DeleteRemoteIptvSource _deleteSource;

  Future<Map<String, RemoteIptvDeleteStatus>> deleteByLocalIdsBestEffort({
    required Set<String> localIds,
    required String? userId,
  }) async {
    final normalizedLocalIds = localIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (normalizedLocalIds.isEmpty) {
      return const <String, RemoteIptvDeleteStatus>{};
    }

    final resolvedUserId = userId?.trim();
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return <String, RemoteIptvDeleteStatus>{
        for (final localId in normalizedLocalIds)
          localId: RemoteIptvDeleteStatus.skippedNoSession,
      };
    }

    try {
      final remoteSources = await _loadSources(accountId: resolvedUserId);
      final matchesByLocalId = <String, List<SupabaseIptvSourceEntity>>{};
      for (final source in remoteSources) {
        final sourceLocalId = source.localId?.trim();
        if (sourceLocalId == null ||
            !normalizedLocalIds.contains(sourceLocalId)) {
          continue;
        }
        final matches = matchesByLocalId.putIfAbsent(
          sourceLocalId,
          () => <SupabaseIptvSourceEntity>[],
        );
        matches.add(source);
      }

      final results = <String, RemoteIptvDeleteStatus>{};
      for (final localId in normalizedLocalIds) {
        final matches = matchesByLocalId[localId];
        if (matches == null || matches.isEmpty) {
          results[localId] = RemoteIptvDeleteStatus.skippedNotFound;
          continue;
        }

        var failed = false;
        for (final match in matches) {
          try {
            await _deleteSource(id: match.id, accountId: resolvedUserId);
          } catch (_) {
            failed = true;
            break;
          }
        }
        results[localId] = failed
            ? RemoteIptvDeleteStatus.failed
            : RemoteIptvDeleteStatus.deleted;
      }
      return results;
    } catch (_) {
      return <String, RemoteIptvDeleteStatus>{
        for (final localId in normalizedLocalIds)
          localId: RemoteIptvDeleteStatus.failed,
      };
    }
  }

  Future<RemoteIptvDeleteStatus> deleteByLocalIdBestEffort({
    required String localId,
    required String? userId,
  }) async {
    final trimmedLocalId = localId.trim();
    if (trimmedLocalId.isEmpty) {
      return RemoteIptvDeleteStatus.skippedNotFound;
    }

    final results = await deleteByLocalIdsBestEffort(
      localIds: <String>{trimmedLocalId},
      userId: userId,
    );
    return results[trimmedLocalId] ?? RemoteIptvDeleteStatus.skippedNotFound;
  }
}
