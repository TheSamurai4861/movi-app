import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/settings/presentation/services/iptv_source_remote_delete_service.dart';

void main() {
  test('status helpers expose when a source may reappear after reconnect', () {
    expect(RemoteIptvDeleteStatus.deleted.remoteDeletionConfirmed, isTrue);
    expect(
      RemoteIptvDeleteStatus.skippedNotFound.remoteDeletionConfirmed,
      isTrue,
    );
    expect(RemoteIptvDeleteStatus.failed.mayReappearAfterReconnect, isTrue);
    expect(
      RemoteIptvDeleteStatus.skippedNoSession.mayReappearAfterReconnect,
      isTrue,
    );
    expect(
      RemoteIptvDeleteStatus
          .skippedRepositoryUnavailable
          .mayReappearAfterReconnect,
      isTrue,
    );
  });

  test('returns skippedNoSession when user is not authenticated', () async {
    var loadCalled = false;
    var deleteCalled = false;
    final service = IptvSourceRemoteDeleteService(
      loadSources: ({required accountId}) async {
        loadCalled = true;
        return const <SupabaseIptvSourceEntity>[];
      },
      deleteSource: ({required id, required accountId}) async {
        deleteCalled = true;
      },
    );

    final result = await service.deleteByLocalIdBestEffort(
      localId: 'local_1',
      userId: null,
    );

    expect(result, RemoteIptvDeleteStatus.skippedNoSession);
    expect(loadCalled, isFalse);
    expect(deleteCalled, isFalse);
  });

  test('deletes remote row when localId match exists', () async {
    String? deletedId;
    String? deletedAccountId;
    final service = IptvSourceRemoteDeleteService(
      loadSources: ({required accountId}) async {
        return <SupabaseIptvSourceEntity>[
          SupabaseIptvSourceEntity(
            id: 'remote_1',
            accountId: accountId,
            name: 'Source',
            localId: 'local_1',
          ),
        ];
      },
      deleteSource: ({required id, required accountId}) async {
        deletedId = id;
        deletedAccountId = accountId;
      },
    );

    final result = await service.deleteByLocalIdBestEffort(
      localId: 'local_1',
      userId: 'user_1',
    );

    expect(result, RemoteIptvDeleteStatus.deleted);
    expect(deletedId, 'remote_1');
    expect(deletedAccountId, 'user_1');
  });

  test('deletes every remote row sharing the same localId', () async {
    final deletedIds = <String>[];
    final service = IptvSourceRemoteDeleteService(
      loadSources: ({required accountId}) async {
        return <SupabaseIptvSourceEntity>[
          SupabaseIptvSourceEntity(
            id: 'remote_1',
            accountId: accountId,
            name: 'Source A',
            localId: 'local_1',
          ),
          SupabaseIptvSourceEntity(
            id: 'remote_2',
            accountId: accountId,
            name: 'Source B',
            localId: 'local_1',
          ),
        ];
      },
      deleteSource: ({required id, required accountId}) async {
        deletedIds.add(id);
      },
    );

    final result = await service.deleteByLocalIdBestEffort(
      localId: 'local_1',
      userId: 'user_1',
    );

    expect(result, RemoteIptvDeleteStatus.deleted);
    expect(deletedIds, <String>['remote_1', 'remote_2']);
  });

  test(
    'retries a batch of suppressed local ids with one remote inventory load',
    () async {
      var loadCalls = 0;
      final deletedIds = <String>[];
      final service = IptvSourceRemoteDeleteService(
        loadSources: ({required accountId}) async {
          loadCalls += 1;
          return <SupabaseIptvSourceEntity>[
            SupabaseIptvSourceEntity(
              id: 'remote_1',
              accountId: accountId,
              name: 'Source A',
              localId: 'local_1',
            ),
            SupabaseIptvSourceEntity(
              id: 'remote_2',
              accountId: accountId,
              name: 'Source A duplicate',
              localId: 'local_1',
            ),
            SupabaseIptvSourceEntity(
              id: 'remote_3',
              accountId: accountId,
              name: 'Source B',
              localId: 'local_2',
            ),
          ];
        },
        deleteSource: ({required id, required accountId}) async {
          deletedIds.add(id);
        },
      );

      final result = await service.deleteByLocalIdsBestEffort(
        localIds: const <String>{'local_1', 'local_2', 'local_missing'},
        userId: 'user_1',
      );

      expect(loadCalls, 1);
      expect(result, <String, RemoteIptvDeleteStatus>{
        'local_1': RemoteIptvDeleteStatus.deleted,
        'local_2': RemoteIptvDeleteStatus.deleted,
        'local_missing': RemoteIptvDeleteStatus.skippedNotFound,
      });
      expect(deletedIds, <String>['remote_1', 'remote_2', 'remote_3']);
    },
  );

  test('returns failed when remote delete throws', () async {
    final service = IptvSourceRemoteDeleteService(
      loadSources: ({required accountId}) async {
        return <SupabaseIptvSourceEntity>[
          SupabaseIptvSourceEntity(
            id: 'remote_1',
            accountId: accountId,
            name: 'Source',
            localId: 'local_1',
          ),
        ];
      },
      deleteSource: ({required id, required accountId}) async {
        throw Exception('network');
      },
    );

    final result = await service.deleteByLocalIdBestEffort(
      localId: 'local_1',
      userId: 'user_1',
    );

    expect(result, RemoteIptvDeleteStatus.failed);
  });
}
