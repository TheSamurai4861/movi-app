import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_season_detail_dto.dart';

import 'package:movi/src/features/tv/data/repositories/tv_repository_impl.dart';
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/core/preferences/locale_preferences.dart';
import 'package:movi/src/core/storage/repositories/watchlist_local_repository.dart';
import 'package:movi/src/core/storage/repositories/continue_watching_local_repository.dart';

import '../../../helpers/in_memory_content_cache.dart';

class _StubTvRemote implements TmdbTvRemoteDataSource {
  @override
  Future<TmdbTvDetailDto> fetchShow(int id) => throw UnimplementedError();

  @override
  Future<TmdbTvSeasonDetailDto> fetchSeason(int showId, int seasonNumber) => throw UnimplementedError();

  @override
  Future<List<TmdbTvSummaryDto>> fetchPopular() => throw UnimplementedError();

  @override
  Future<List<TmdbTvSummaryDto>> searchShows(String query) => throw UnimplementedError();
}

class _FakeWatchlist implements WatchlistLocalRepository {
  _FakeWatchlist(this._entries);
  final List<WatchlistEntry> _entries;

  @override
  Future<bool> exists(String contentId, ContentType type) async =>
      _entries.any((e) => e.contentId == contentId && e.type == type);

  @override
  Future<List<WatchlistEntry>> readAll(ContentType type) async =>
      _entries.where((e) => e.type == type).toList(growable: false);

  @override
  Future<void> remove(String contentId, ContentType type) async {}

  @override
  Future<void> upsert(WatchlistEntry entry) async {}
}

class _FakeCW implements ContinueWatchingLocalRepository {
  _FakeCW(this._entries);
  final List<ContinueWatchingEntry> _entries;

  @override
  Future<List<ContinueWatchingEntry>> readAll(ContentType type) async =>
      _entries.where((e) => e.type == type).toList(growable: false);

  @override
  Future<void> remove(String contentId, ContentType type) async {}

  @override
  Future<void> upsert(ContinueWatchingEntry entry) async {}
}

void main() {
  group('TvRepositoryImpl (watchlist & continue watching)', () {
    late TvRepositoryImpl repo;

    setUp(() {
      final cache = InMemoryContentCacheRepository();
      final local = TvLocalDataSource(cache, LocalePreferences());
      repo = TvRepositoryImpl(
        _StubTvRemote(),
        const TmdbImageResolver(),
        _FakeWatchlist([
          WatchlistEntry(
            contentId: '1399',
            type: ContentType.series,
            title: 'Game of Thrones',
            poster: Uri.parse('https://image.tmdb.org/t/p/w500/poster.jpg'),
            addedAt: DateTime.now(),
          ),
          WatchlistEntry(
            contentId: '9999',
            type: ContentType.series,
            title: 'No Poster Show',
            poster: null, // should be filtered out
            addedAt: DateTime.now(),
          ),
        ]),
        local,
        _FakeCW([
          ContinueWatchingEntry(
            contentId: '1399',
            type: ContentType.series,
            title: 'Game of Thrones',
            poster: Uri.parse('https://image.tmdb.org/t/p/w500/poster.jpg'),
            position: const Duration(minutes: 10),
            duration: const Duration(minutes: 55),
            season: 1,
            episode: 2,
            updatedAt: DateTime.now(),
          ),
          ContinueWatchingEntry(
            contentId: '8888',
            type: ContentType.series,
            title: 'Another Show',
            poster: null, // filtered
            position: const Duration(minutes: 1),
            duration: const Duration(minutes: 45),
            season: 1,
            episode: 1,
            updatedAt: DateTime.now(),
          ),
        ]),
      );
    });

    test('getUserWatchlist maps only entries with poster', () async {
      final list = await repo.getUserWatchlist();
      expect(list.length, 1);
      expect(list.first.id.value, '1399');
      expect(list.first.title.value, 'Game of Thrones');
    });

    test('getContinueWatching maps only entries with poster', () async {
      final list = await repo.getContinueWatching();
      expect(list.length, 1);
      expect(list.first.id.value, '1399');
      expect(list.first.title.value, 'Game of Thrones');
    });
  });
}
