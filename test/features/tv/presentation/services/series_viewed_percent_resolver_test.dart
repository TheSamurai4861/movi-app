import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
import 'package:movi/src/features/tv/presentation/services/series_viewed_percent_resolver.dart';

void main() {
  test('returns ordinal progress based on the latest tracked episode', () {
    final percent = resolveSeriesViewedPercent(
      seasons: <SeasonViewModel>[
        SeasonViewModel(
          id: 's1',
          seasonNumber: 1,
          title: 'Season 1',
          episodes: <EpisodeViewModel>[
            EpisodeViewModel(id: 's1e1', episodeNumber: 1, title: 'Ep 1'),
            EpisodeViewModel(id: 's1e2', episodeNumber: 2, title: 'Ep 2'),
          ],
        ),
        SeasonViewModel(
          id: 's2',
          seasonNumber: 2,
          title: 'Season 2',
          episodes: <EpisodeViewModel>[
            EpisodeViewModel(id: 's2e1', episodeNumber: 1, title: 'Ep 1'),
            EpisodeViewModel(id: 's2e2', episodeNumber: 2, title: 'Ep 2'),
          ],
        ),
      ],
      seasonNumber: 2,
      episodeNumber: 1,
      position: null,
      duration: null,
    );

    expect(percent, 0.75);
  });

  test(
    'returns complete when no episode is mapped but progress is near end',
    () {
      final percent = resolveSeriesViewedPercent(
        seasons: <SeasonViewModel>[
          SeasonViewModel(
            id: 's1',
            seasonNumber: 1,
            title: 'Season 1',
            episodes: <EpisodeViewModel>[
              EpisodeViewModel(id: 's1e1', episodeNumber: 1, title: 'Ep 1'),
            ],
          ),
        ],
        seasonNumber: null,
        episodeNumber: null,
        position: const Duration(minutes: 57),
        duration: const Duration(minutes: 60),
      );

      expect(percent, 1.0);
    },
  );

  test('returns null when no tracked episode or usable progress exists', () {
    final percent = resolveSeriesViewedPercent(
      seasons: <SeasonViewModel>[
        SeasonViewModel(
          id: 's1',
          seasonNumber: 1,
          title: 'Season 1',
          episodes: <EpisodeViewModel>[
            EpisodeViewModel(id: 's1e1', episodeNumber: 1, title: 'Ep 1'),
          ],
        ),
      ],
      seasonNumber: 9,
      episodeNumber: 9,
      position: const Duration(minutes: 10),
      duration: const Duration(minutes: 60),
    );

    expect(percent, isNull);
  });

  test(
    'returns complete when manually marked seen without playable progress',
    () {
      final percent = resolveSeriesViewedPercent(
        seasons: <SeasonViewModel>[
          SeasonViewModel(
            id: 's1',
            seasonNumber: 1,
            title: 'Season 1',
            episodes: <EpisodeViewModel>[
              EpisodeViewModel(id: 's1e1', episodeNumber: 1, title: 'Ep 1'),
            ],
          ),
        ],
        seasonNumber: null,
        episodeNumber: null,
        position: const Duration(minutes: 10),
        duration: const Duration(minutes: 60),
        isMarkedSeen: true,
      );

      expect(percent, 1.0);
    },
  );
}
