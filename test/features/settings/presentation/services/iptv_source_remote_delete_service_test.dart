import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
import 'package:movi/src/features/settings/presentation/services/iptv_source_remote_delete_service.dart';

void main() {
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
