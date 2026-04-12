import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

void main() {
  test('rebuildTvDetailViewModelWithUpdatedSeasons preserves hero media fields', () {
    final baseVm = TvDetailViewModel(
      title: 'Series',
      yearText: '2024',
      seasonsCountText: '2 seasons',
      ratingText: '8.1',
      overviewText: 'Overview',
      cast: const <MoviPerson>[],
      seasons: <SeasonViewModel>[
        SeasonViewModel(
          id: '1',
          seasonNumber: 1,
          title: 'Season 1',
          episodes: const <EpisodeViewModel>[],
        ),
      ],
      logo: Uri.parse('https://image.tmdb.org/t/p/original/logo.svg'),
      poster: Uri.parse('https://image.tmdb.org/t/p/w780/poster.jpg'),
      posterBackground: Uri.parse(
        'https://image.tmdb.org/t/p/original/poster_bg.jpg',
      ),
      backdrop: Uri.parse('https://image.tmdb.org/t/p/original/backdrop.jpg'),
      language: 'fr-FR',
    );

    final updated = rebuildTvDetailViewModelWithUpdatedSeasons(baseVm, <SeasonViewModel>[
      SeasonViewModel(
        id: '1',
        seasonNumber: 1,
        title: 'Season 1',
        episodes: <EpisodeViewModel>[
          EpisodeViewModel(
            id: '101',
            episodeNumber: 1,
            title: 'Ep 1',
            isAvailableInPlaylist: true,
          ),
        ],
      ),
    ]);

    expect(updated.logo, baseVm.logo);
    expect(updated.poster, baseVm.poster);
    expect(updated.posterBackground, baseVm.posterBackground);
    expect(updated.backdrop, baseVm.backdrop);
    expect(updated.seasons, hasLength(1));
  });

  test('rebuildTvDetailViewModelWithUpdatedSeasons keeps loading or empty seasons', () {
    final baseVm = TvDetailViewModel(
      title: 'Series',
      yearText: '2024',
      seasonsCountText: '3 seasons',
      ratingText: '8.1',
      overviewText: 'Overview',
      cast: const <MoviPerson>[],
      seasons: const <SeasonViewModel>[],
      logo: Uri.parse('https://image.tmdb.org/t/p/original/logo.png'),
      poster: Uri.parse('https://image.tmdb.org/t/p/w780/poster.jpg'),
      posterBackground: null,
      backdrop: Uri.parse('https://image.tmdb.org/t/p/original/backdrop.jpg'),
      language: 'fr-FR',
    );

    final updated = rebuildTvDetailViewModelWithUpdatedSeasons(baseVm, <SeasonViewModel>[
      SeasonViewModel(
        id: 'loading',
        seasonNumber: 1,
        title: 'Loading',
        episodes: const <EpisodeViewModel>[],
        isLoadingEpisodes: true,
      ),
      SeasonViewModel(
        id: 'empty',
        seasonNumber: 2,
        title: 'Empty',
        episodes: const <EpisodeViewModel>[],
      ),
      SeasonViewModel(
        id: 'unavailable',
        seasonNumber: 3,
        title: 'Unavailable',
        episodes: <EpisodeViewModel>[
          EpisodeViewModel(
            id: '301',
            episodeNumber: 1,
            title: 'Ep',
            isAvailableInPlaylist: false,
          ),
        ],
      ),
    ]);

    expect(updated.seasons.map((s) => s.id), containsAll(<String>['loading', 'empty']));
    expect(updated.seasons.map((s) => s.id), isNot(contains('unavailable')));
    expect(updated.logo, isNotNull);
  });
}

