import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/storage/repositories/iptv_local_repository.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
import 'package:movi/src/features/player/application/services/next_episode_service.dart';
import 'package:movi/src/features/player/domain/entities/video_source.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';

class _FakeIptvLocalRepository extends IptvLocalRepository {
  _FakeIptvLocalRepository(this._items);
  final List<XtreamPlaylistItem> _items;

  @override
  Future<List<XtreamAccount>> getAccounts() async {
    return [
      XtreamAccount(
        id: 'acc',
        alias: 'acc',
        endpoint: XtreamEndpoint.parse('http://host:80'),
        username: 'u',
        status: XtreamAccountStatus.active,
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<XtreamPlaylist>> getPlaylists(String accountId) async {
    return [
      XtreamPlaylist(
        id: '1',
        accountId: 'acc',
        title: 'series',
        type: XtreamPlaylistType.series,
        items: _items,
      ),
    ];
  }

  // minimal overrides only
}

class _FakeUrlBuilder implements XtreamStreamUrlBuilder {
  @override
  Future<String?> buildStreamUrlFromSeriesItem({required XtreamPlaylistItem item, required int seasonNumber, required int episodeNumber}) async {
    return 'https://example.com/${item.streamId}/s$seasonNumber/e$episodeNumber';
  }

  @override
  Future<String?> buildMovieStreamUrl({required int streamId, required String accountId}) async => 'https://example.com/$streamId';

  @override
  Future<String?> buildEpisodeStreamUrl({required int episodeId, required String accountId, String? extension, int? seriesId}) async => 'https://example.com/e$episodeId';

  @override
  Future<String?> buildStreamUrlFromMovieItem(XtreamPlaylistItem item) async => 'https://example.com/${item.streamId}';
}

SeasonViewModel _season(int number, List<int> episodes) {
  return SeasonViewModel(
    id: 's$number',
    seasonNumber: number,
    title: 'Saison $number',
    episodes: episodes
        .map((e) => EpisodeViewModel(id: 'e$e', episodeNumber: e, title: 'Ep $e'))
        .toList(),
  );
}

void main() {
  group('NextEpisodeService', () {
    test('computes next in same season', () async {
      final iptv = _FakeIptvLocalRepository([
        XtreamPlaylistItem(
          accountId: 'acc',
          categoryId: '1',
          categoryName: 'Series',
          streamId: 100,
          title: 'Show',
          type: XtreamPlaylistItemType.series,
          tmdbId: 123,
          posterUrl: null,
        ),
      ]);
      final svc = NextEpisodeService(iptvLocal: iptv, urlBuilder: _FakeUrlBuilder());
      final seasons = [
        _season(1, [1, 2, 3]),
      ];

      final result = await svc.computeNext(
        current: VideoSource(
          url: 'https://example.com/100/s1/e1',
          title: 'S01E01',
          contentId: '123',
          contentType: ContentType.series,
          season: 1,
          episode: 1,
        ),
        seasons: seasons,
        seriesId: '123',
        seriesTitle: 'Show',
      );

      expect(result.source, isNotNull);
      expect(result.source!.season, 1);
      expect(result.source!.episode, 2);
    });

    test('computes next season when at end', () async {
      final iptv = _FakeIptvLocalRepository([
        XtreamPlaylistItem(
          accountId: 'acc',
          categoryId: '1',
          categoryName: 'Series',
          streamId: 100,
          title: 'Show',
          type: XtreamPlaylistItemType.series,
          tmdbId: 123,
          posterUrl: null,
        ),
      ]);
      final svc = NextEpisodeService(iptvLocal: iptv, urlBuilder: _FakeUrlBuilder());
      final seasons = [
        _season(1, [1, 2]),
        _season(2, [1, 2]),
      ];

      final result = await svc.computeNext(
        current: VideoSource(
          url: 'https://example.com/100/s1/e2',
          title: 'S01E02',
          contentId: '123',
          contentType: ContentType.series,
          season: 1,
          episode: 2,
        ),
        seasons: seasons,
        seriesId: '123',
        seriesTitle: 'Show',
      );

      expect(result.source, isNotNull);
      expect(result.source!.season, 2);
      expect(result.source!.episode, 1);
      expect(result.source!.url.contains('/e1'), isTrue);
    });

    test('handles global numbering conversion', () async {
      final iptv = _FakeIptvLocalRepository([
        XtreamPlaylistItem(
          accountId: 'acc',
          categoryId: '1',
          categoryName: 'Series',
          streamId: 100,
          title: 'Show',
          type: XtreamPlaylistItemType.series,
          tmdbId: 123,
          posterUrl: null,
        ),
      ]);
      final svc = NextEpisodeService(iptvLocal: iptv, urlBuilder: _FakeUrlBuilder());
      final seasons = [
        _season(1, [1, 2]),
        // Global numbering for season 2 (starts at 3)
        _season(2, [3, 4, 5]),
      ];

      final result = await svc.computeNext(
        current: VideoSource(
          url: 'https://example.com/100/s1/e2',
          title: 'S01E02',
          contentId: '123',
          contentType: ContentType.series,
          season: 1,
          episode: 2,
        ),
        seasons: seasons,
        seriesId: '123',
        seriesTitle: 'Show',
      );

      expect(result.source, isNotNull);
      expect(result.source!.season, 2);
      expect(result.source!.episode, 3);
      expect(result.source!.url.contains('/e1'), isTrue);
    });

    test('fails when not found in playlist', () async {
      final iptv = _FakeIptvLocalRepository([]);
      final svc = NextEpisodeService(iptvLocal: iptv, urlBuilder: _FakeUrlBuilder());
      final seasons = [_season(1, [1, 2])];

      final result = await svc.computeNext(
        current: VideoSource(
          url: 'u',
          title: 't',
          contentId: '123',
          contentType: ContentType.series,
          season: 1,
          episode: 1,
        ),
        seasons: seasons,
        seriesId: '123',
        seriesTitle: 'Show',
      );
      expect(result.error, isNotNull);
      expect(result.error!.code, 'not_found_in_playlist');
    });
  });
}