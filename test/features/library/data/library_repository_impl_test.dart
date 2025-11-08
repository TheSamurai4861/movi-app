import 'package:flutter_test/flutter_test.dart';

import 'package:movi/src/features/library/data/repositories/library_repository_impl.dart';
import 'package:movi/src/core/storage/repositories/watchlist_local_repository.dart';
import 'package:movi/src/core/storage/repositories/history_local_repository.dart';
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';

import '../../../helpers/database_initializer.dart';

class _FakeHistory implements HistoryLocalRepository {
  @override
  Future<List<HistoryEntry>> readAll(ContentType type) async => const [];

  @override
  Future<void> remove(String contentId, ContentType type) async {}

  @override
  Future<void> upsertPlay({
    required String contentId,
    required ContentType type,
    required String title,
    Uri? poster,
    DateTime? playedAt,
    Duration? position,
    Duration? duration,
    int? season,
    int? episode,
  }) async {}
}

class _FakePlaylists implements PlaylistRepository {
  @override
  Future<void> addItem({required PlaylistId playlistId, required PlaylistItem item}) async {}
  @override
  Future<void> createPlaylist({required PlaylistId id, required MediaTitle title, String? description, Uri? cover, required String owner, bool isPublic = false}) async {}
  @override
  Future<void> deletePlaylist(PlaylistId id) async {}
  @override
  Future<Playlist> getPlaylist(PlaylistId id) => throw UnimplementedError();
  @override
  Future<List<PlaylistSummary>> getFeaturedPlaylists() async => const [];
  @override
  Future<List<PlaylistSummary>> getUserPlaylists(String userId) async => const [];
  @override
  Future<void> removeItem({required PlaylistId playlistId, required PlaylistItem item}) async {}
  @override
  Future<List<PlaylistSummary>> searchPlaylists(String query) async => const [];
  @override
  Future<void> renamePlaylist({required PlaylistId id, required MediaTitle title}) async {}
  @override
  Future<void> reorderItem({required PlaylistId playlistId, required int fromPosition, required int toPosition}) async {}
  @override
  Future<void> setOwner({required PlaylistId id, required String owner}) async {}
}

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  test('getLikedPersons maps people from watchlist (poster required)', () async {
    final watchlist = const WatchlistLocalRepositoryImpl();
    // Insert two persons, one with poster and one without; plus a movie ignored
    await watchlist.upsert(WatchlistEntry(
      contentId: '287',
      type: ContentType.person,
      title: 'Brad Pitt',
      poster: Uri.parse('https://image.tmdb.org/t/p/w500/brad.jpg'),
      addedAt: DateTime.now(),
    ));
    await watchlist.upsert(WatchlistEntry(
      contentId: '819',
      type: ContentType.person,
      title: 'Edward Norton',
      poster: null,
      addedAt: DateTime.now(),
    ));
    await watchlist.upsert(WatchlistEntry(
      contentId: '99999',
      type: ContentType.movie,
      title: 'Fight Club',
      poster: null,
      addedAt: DateTime.now(),
    ));

    final repo = LibraryRepositoryImpl(watchlist, _FakeHistory(), _FakePlaylists());
    final liked = await repo.getLikedPersons();

    expect(liked.length, 1);
    expect(liked.first.id.value, '287');
    expect(liked.first.name, 'Brad Pitt');
    expect(liked.first.photo, isNotNull);
  });
}
