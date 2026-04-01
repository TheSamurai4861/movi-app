import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';

enum RemoteIptvDeleteStatus {
  deleted,
  skippedNoSession,
  skippedRepositoryUnavailable,
  skippedNotFound,
  failed,
}

typedef LoadRemoteIptvSources =
    Future<List<SupabaseIptvSourceEntity>> Function({
      required String accountId,
    });
typedef DeleteRemoteIptvSource =
    Future<void> Function({required String id, required String accountId});

class IptvSourceRemoteDeleteService {
  const IptvSourceRemoteDeleteService({
    required LoadRemoteIptvSources loadSources,
    required DeleteRemoteIptvSource deleteSource,
  }) : _loadSources = loadSources,
       _deleteSource = deleteSource;

  final LoadRemoteIptvSources _loadSources;
  final DeleteRemoteIptvSource _deleteSource;

  Future<RemoteIptvDeleteStatus> deleteByLocalIdBestEffort({
    required String localId,
    required String? userId,
  }) async {
    final resolvedUserId = userId?.trim();
    if (resolvedUserId == null || resolvedUserId.isEmpty) {
      return RemoteIptvDeleteStatus.skippedNoSession;
    }

    final trimmedLocalId = localId.trim();
    if (trimmedLocalId.isEmpty) {
      return RemoteIptvDeleteStatus.skippedNotFound;
    }

    try {
      final remoteSources = await _loadSources(accountId: resolvedUserId);
      SupabaseIptvSourceEntity? remoteMatch;
      for (final source in remoteSources) {
        if ((source.localId ?? '').trim() == trimmedLocalId) {
          remoteMatch = source;
          break;
        }
      }
      if (remoteMatch == null) {
        return RemoteIptvDeleteStatus.skippedNotFound;
      }

      await _deleteSource(id: remoteMatch.id, accountId: resolvedUserId);
      return RemoteIptvDeleteStatus.deleted;
    } catch (_) {
      return RemoteIptvDeleteStatus.failed;
    }
  }
}
