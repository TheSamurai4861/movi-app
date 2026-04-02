import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart'
    as mdp;
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test('returns null when duration is invalid', () async {
    final container = _createContainer();
    addTearDown(container.dispose);
    final historyRepo = _historyRepoFrom(container);

    const movieId = '603';
    historyRepo.entry = const PlaybackHistoryEntry(
      contentId: movieId,
      type: ContentType.movie,
      title: 'The Matrix',
      lastPosition: Duration(minutes: 20),
      duration: Duration.zero,
    );

    final resume = await container.read(
      mdp.movieResumePositionProvider(movieId).future,
    );
    expect(resume, isNull);
  });

  test('returns null when position is null', () async {
    final container = _createContainer();
    addTearDown(container.dispose);
    final historyRepo = _historyRepoFrom(container);

    const movieId = '603';
    historyRepo.entry = const PlaybackHistoryEntry(
      contentId: movieId,
      type: ContentType.movie,
      title: 'The Matrix',
      duration: Duration(minutes: 120),
    );

    final resume = await container.read(
      mdp.movieResumePositionProvider(movieId).future,
    );
    expect(resume, isNull);
  });

  test('returns null when progress is above max threshold', () async {
    final container = _createContainer();
    addTearDown(container.dispose);
    final historyRepo = _historyRepoFrom(container);

    const movieId = '603';
    historyRepo.entry = const PlaybackHistoryEntry(
      contentId: movieId,
      type: ContentType.movie,
      title: 'The Matrix',
      lastPosition: Duration(minutes: 115),
      duration: Duration(minutes: 120),
    );

    final resume = await container.read(
      mdp.movieResumePositionProvider(movieId).future,
    );
    expect(resume, isNull);
  });

  test(
    'movieResumePositionProvider refreshes after targeted invalidation',
    () async {
      final container = _createContainer();
      addTearDown(container.dispose);
      final historyRepo = _historyRepoFrom(container);

      const movieId = '603';
      historyRepo.entry = const PlaybackHistoryEntry(
        contentId: movieId,
        type: ContentType.movie,
        title: 'The Matrix',
        lastPosition: Duration(seconds: 8),
        duration: Duration(minutes: 120),
      );

      final first = await container.read(
        mdp.movieResumePositionProvider(movieId).future,
      );
      expect(first, isNull);

      historyRepo.entry = const PlaybackHistoryEntry(
        contentId: movieId,
        type: ContentType.movie,
        title: 'The Matrix',
        lastPosition: Duration(minutes: 40),
        duration: Duration(minutes: 120),
      );
      container.invalidate(mdp.movieResumePositionProvider(movieId));

      final refreshed = await container.read(
        mdp.movieResumePositionProvider(movieId).future,
      );
      expect(refreshed, const Duration(minutes: 40));
    },
  );
}

ProviderContainer _createContainer() {
  final getIt = GetIt.asNewInstance();
  final historyRepo = _MutablePlaybackHistoryRepository();
  getIt.registerSingleton<PlaybackHistoryRepository>(historyRepo);
  return ProviderContainer(
    overrides: [
      slProvider.overrideWithValue(getIt),
      currentUserIdProvider.overrideWith((ref) => 'user-local'),
    ],
  );
}

_MutablePlaybackHistoryRepository _historyRepoFrom(
  ProviderContainer container,
) {
  return container.read(slProvider)<PlaybackHistoryRepository>()
      as _MutablePlaybackHistoryRepository;
}

class _MutablePlaybackHistoryRepository implements PlaybackHistoryRepository {
  PlaybackHistoryEntry? entry;

  @override
  Future<PlaybackHistoryEntry?> getEntry(
    String contentId,
    ContentType type, {
    int? season,
    int? episode,
    String? userId,
  }) async {
    return entry;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError('Unexpected call: $invocation');
  }
}
