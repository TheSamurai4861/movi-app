import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/features/tv/domain/entities/episode_playback_season_snapshot.dart';
import 'package:movi/src/features/tv/domain/usecases/resolve_series_playback_target.dart';
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
import 'package:movi/src/shared/domain/services/media_resume_decision.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  const seriesId = 'series-1';

  group('seriesPlaybackLaunchPlanProvider', () {
    test('keeps DB resume target stable while snapshots transition', () async {
      final getIt = GetIt.asNewInstance();
      getIt.registerSingleton<PlaybackHistoryRepository>(
        _FakePlaybackHistoryRepository(
          seriesResumeState: const PlaybackHistoryEntry(
            contentId: seriesId,
            type: ContentType.series,
            title: 'Fallback test',
            season: 3,
            episode: 7,
            lastPosition: Duration(minutes: 14),
            duration: Duration(minutes: 50),
          ),
        ),
      );

      var snapshots = const <EpisodePlaybackSeasonSnapshot>[];

      final container = ProviderContainer(
        overrides: [
          slProvider.overrideWithValue(getIt),
          currentUserIdProvider.overrideWithValue('user-a'),
          resolveSeriesPlaybackTargetUseCaseProvider.overrideWithValue(
            const ResolveSeriesPlaybackTarget(),
          ),
          seriesLoadedSeasonSnapshotsProvider(
            seriesId,
          ).overrideWith((ref) => snapshots),
        ],
      );
      addTearDown(container.dispose);

      final initialPlan = await container.read(
        seriesPlaybackLaunchPlanProvider(seriesId).future,
      );

      expect(initialPlan, isNotNull);
      expect(initialPlan?.season, 3);
      expect(initialPlan?.episode, 7);
      expect(initialPlan?.resumePosition, const Duration(minutes: 14));
      expect(initialPlan?.reasonCode, ResumeReasonCode.applied);

      snapshots = [
        EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
          seasonNumber: 1,
          episodeNumbers: const <int>[1, 2, 3],
        ),
      ];
      container.invalidate(seriesPlaybackLaunchPlanProvider(seriesId));

      final afterLoadingPlan = await container.read(
        seriesPlaybackLaunchPlanProvider(seriesId).future,
      );

      expect(afterLoadingPlan, isNotNull);
      expect(afterLoadingPlan?.season, 3);
      expect(afterLoadingPlan?.episode, 7);
      expect(afterLoadingPlan?.resumePosition, const Duration(minutes: 14));
      expect(afterLoadingPlan?.reasonCode, ResumeReasonCode.applied);
    });

    test(
      'falls back to first available episode when DB resume is absent',
      () async {
        final getIt = GetIt.asNewInstance();
        getIt.registerSingleton<PlaybackHistoryRepository>(
          _FakePlaybackHistoryRepository(seriesResumeState: null),
        );

        final container = ProviderContainer(
          overrides: [
            slProvider.overrideWithValue(getIt),
            currentUserIdProvider.overrideWithValue('user-a'),
            resolveSeriesPlaybackTargetUseCaseProvider.overrideWithValue(
              const ResolveSeriesPlaybackTarget(),
            ),
            seriesLoadedSeasonSnapshotsProvider(seriesId).overrideWith(
              (ref) => [
                EpisodePlaybackSeasonSnapshot.fromEpisodeNumbers(
                  seasonNumber: 2,
                  episodeNumbers: const <int>[5, 6],
                ),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);

        final plan = await container.read(
          seriesPlaybackLaunchPlanProvider(seriesId).future,
        );

        expect(plan, isNotNull);
        expect(plan?.season, 2);
        expect(plan?.episode, 5);
        expect(plan?.isResumeEligible, isFalse);
        expect(plan?.reasonCode, ResumeReasonCode.noPosition);
      },
    );
  });
}

class _FakePlaybackHistoryRepository implements PlaybackHistoryRepository {
  _FakePlaybackHistoryRepository({required this.seriesResumeState});

  final PlaybackHistoryEntry? seriesResumeState;

  @override
  Future<PlaybackHistoryEntry?> getSeriesResumeState(
    String seriesId, {
    String? userId,
  }) async => seriesResumeState;

  @override
  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  }) async => null;

  @override
  Future<void> remove(
    String contentId,
    ContentType type, {
    String? userId,
  }) async {}

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
    String? userId,
  }) async {}
}
