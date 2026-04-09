import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart'
    as mdp;
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

void main() {
  test('movieSeenProvider stays false below the completed threshold', () async {
    final getIt = GetIt.asNewInstance();
    final historyRepo = _MutablePlaybackHistoryRepository(
      entry: const PlaybackHistoryEntry(
        contentId: 'movie-1',
        type: ContentType.movie,
        title: 'Movie',
        lastPosition: Duration(minutes: 108),
        duration: Duration(minutes: 120),
      ),
    );
    getIt.registerSingleton<PlaybackHistoryRepository>(historyRepo);

    final container = ProviderContainer(
      overrides: [slProvider.overrideWithValue(getIt)],
    );
    addTearDown(container.dispose);

    final isSeen = await container.read(
      mdp.movieSeenProvider('movie-1').future,
    );

    expect(isSeen, isFalse);
  });
}

class _MutablePlaybackHistoryRepository implements PlaybackHistoryRepository {
  _MutablePlaybackHistoryRepository({this.entry});

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
